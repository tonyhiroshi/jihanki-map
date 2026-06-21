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

Firebaseコンソール → Firestore Database →「ルール」タブ：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /machines/{machineId} {
      // 誰でも読める（マップ検索アプリなので一般公開でOKという前提）
      allow read: if true;

      // 書き込み（登録・更新）は許可するが、変な内容を弾くチェックを入れる
      allow create: if request.resource.data.maker is string
                    && request.resource.data.lat is number
                    && request.resource.data.lng is number;

      allow update: if request.resource.data.maker is string;

      // 削除は今回未実装。許可したい場合のみ有効化
      allow delete: if false;
    }
  }
}
```

これは最低限の「型チェック」レベルのルールです。荒らし対策（投稿頻度制限・
内容モデレーションなど）まで考えるなら、Firebase Authenticationで匿名ログインを
必須にし、`request.auth != null` を条件に加える、Cloud Functionsで投稿内容を
チェックする、といった対策が次のステップになります。必要であればこちらも
一緒に組みます。

## 6. 既知の制約・次の検討事項
- 写真はBase64文字列としてFirestoreの1ドキュメント内に保存しています。
  Firestoreの1ドキュメントの上限は1MBなので、写真3枚分が収まるよう
  圧縮していますが、画質を上げたい場合は Firebase Storage に画像を置き、
  ドキュメントにはURLだけを持たせる構成に変更するのがおすすめです。
- 地域検索（Nominatim）は無料の公開APIのため、リクエスト数が多い場合に
  レート制限される可能性があります。本格運用する場合はGoogle Geocoding API
  などの有償サービスへの切り替えを検討してください。
