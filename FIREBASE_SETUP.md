# Firebase連携セットアップ手順

このアプリ（vending-map.html）は、複数人でデータを共有できるように
Google Firebase の Firestore（クラウムDB）を使う前提で作られています。

## 1. Firebaseプロジェクトを作る
1. https://console.firebase.google.com を開く（Googleアカウントでログイン）
2. 「プロジェクトを追加」→ 適当な名前（例: jihanki-map）で作成
3. Google アナリティクスは「無効」でOK（後から有効化も可能）

## 2. Firestore Database を有効化する
1. 左メニュー「ビルド」→「Firestore Database」
2. 「データベースの作成」
3. ロケーションは `asia-northeast1`（東京）を推奨
4. 開始時のルールは「テストモード」を選択（後で本番用ルールに差し替えます）

## 3. ウェブアプリを登録して設定値を取得する
1. プロジェクト概要（左上の歯車アイコン横）→「プロジェクトの設定」
2. 「アプリを追加」→ ウェブ(</>) アイコンを選択
3. アプリ名は適当でOK（例: vending-map-web）。Firebase Hostingは今回はチェック不要
4. 表示される `firebaseConfig` オブジェクトをコピー

```js
const firebaseConfig = {
  apiKey: "AIza......",
  authDomain: "jihanki-map.firebaseapp.com",
  projectId: "jihanki-map",
  storageBucket: "jihanki-map.appspot.com",
  messagingSenderId: "1234567890",
  appId: "1:1234567890:web:xxxxxxxxxxxx"
};
```

5. `vending-map.html` 内の同名の `firebaseConfig`（ファイル上部、
   `// Firebase / Firestore 設定` というコメントのすぐ下）を、
   この内容で書き換える

## 4. 動作確認
1. ローカルサーバーを立てて開く（`file://` だと現在地取得などが制限されるため推奨）
   ```bash
   python3 -m http.server 8000
   ```
2. ブラウザで `http://localhost:8000/vending-map.html` を開く
3. 地図をタップして自販機を1件登録してみる
4. Firebaseコンソールの Firestore Database を見て、`machines` コレクションに
   ドキュメントが1件増えていれば成功
5. 別のブラウザ（またはスマホ）で同じURLを開いて、リアルタイムに反映されるか確認

## 5. 本番運用前にFirestoreのルールを差し替える（重要）

テストモードのままだと「誰でも全データを読み書きできる」状態が
一定期間後に「誰も読み書きできない」状態に自動的に切り替わり、かつ
途中までは完全に無防備な状態です。最低限、以下のように差し替えてください。

**このリポジトリの [`firestore.rules`](firestore.rules) が正本です。** 内容を変更したら
忘れずに公開してください（下記いずれか）。

- Firebaseコンソール → Firestore Database →「ルール」タブに貼り付けて「公開」
- もしくは Firebase CLI: `firebase deploy --only firestore:rules`

現在のルール（`firestore.rules` と同一）：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 自販機（メタ情報＋サムネイル）
    match /machines/{id} {
      // 誰でも閲覧可（公開マップのため）
      allow read: if true;
      // 作成はログイン必須＋自分のIDを記録＋最低限の型チェック
      allow create: if request.auth != null
                    && request.resource.data.ownerUid == request.auth.uid
                    && request.resource.data.maker is string
                    && request.resource.data.lat is number
                    && request.resource.data.lng is number;
      // 情報・写真の更新はログインしていれば誰でも可（鮮度維持）。
      // 変更できるのは下記のキーのみ。位置・所有者・作成日時は変更不可
      // （許可リスト外のキーが含まれると拒否されるため、自動的に保護される）。
      allow update: if request.auth != null
                    && request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['category','maker','products','pays','feature','price','note','updatedAt','lastEditUid','thumb','photoCount']);
      // ピンの位置（lat/lng）の修正は投稿者本人のみ。所有者・作成日時は変更不可。
      allow update: if request.auth != null
                    && resource.data.ownerUid == request.auth.uid
                    && request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['lat','lng','updatedAt']);
      // 削除は投稿者本人のみ
      allow delete: if request.auth != null
                    && resource.data.ownerUid == request.auth.uid;
    }

    // 写真本体（詳細表示時に読み込む）。
    // 編集機能で誰でも差し替えられるよう、ログインユーザーは書き込み可。
    match /photos/{id} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    // 通報（作成のみ許可。閲覧・編集・削除は管理者がコンソールで行う）
    match /reports/{id} {
      allow create: if request.auth != null;
      allow read, update, delete: if false;
    }

    // 貢献ランキング用のユーザー情報
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && (!('nickname' in request.resource.data) || request.resource.data.nickname is string);
    }
  }
}
```

ポイント：
- **匿名ログイン必須**（`request.auth != null`）。Firebase Authentication で「匿名」を
  有効化しておく必要があります。アプリ起動時に自動で匿名サインインします。
- **削除・ピン位置の修正は投稿者本人のみ**（`ownerUid == request.auth.uid`）。
- **情報・写真の更新は誰でも可**（鮮度維持のため）。ただし変更できるキーを許可リストで
  限定し、位置・所有者・作成日時は本人以外から変更できないようにしています。
- さらなる荒らし対策（投稿頻度制限・内容モデレーション）まで考えるなら、Cloud Functions で
  投稿内容をチェックするのが次のステップです。必要であれば一緒に組みます。

## 6. 既知の制約・次の検討事項
- 写真はBase64文字列としてFirestoreの1ドキュメント内に保存しています。
  Firestoreの1ドキュメントの上限は1MBなので、写真3枚分が収まるよう
  圧縮していますが、画質を上げたい場合は Firebase Storage に画像を置き、
  ドキュメントにはURLだけを持たせる構成に変更するのがおすすめです。
- 地域検索（Nominatim）は無料の公開APIのため、リクエスト数が多い場合に
  レート制限される可能性があります。本格運用する場合はGoogle Geocoding API
  などの有償サービスへの切り替えを検討してください。
