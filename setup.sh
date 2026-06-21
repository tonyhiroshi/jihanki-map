#!/bin/bash
set -e
echo "=== 自販機マップ Firebase 自動セットアップ ==="
echo ""

# 1. Node.js確認
if ! command -v node &> /dev/null; then
  echo "❌ Node.jsが見つかりません。https://nodejs.org からインストールしてください。"
  exit 1
fi
echo "✅ Node.js: $(node -v)"

# 2. Firebase CLIインストール
if ! command -v firebase &> /dev/null; then
  echo "📦 Firebase CLIをインストールします..."
  npm install -g firebase-tools
fi
echo "✅ Firebase CLI: $(firebase --version)"

# 3. ログイン（ここだけブラウザでの操作が必要）
echo ""
echo "👉 ブラウザが開きます。Googleアカウントでログインしてください。"
firebase login

# 4. プロジェクト作成
echo ""
read -p "Firebaseプロジェクト名を入力してください（例: jihanki-map）: " PROJECT_NAME
firebase projects:create "$PROJECT_NAME" --display-name "$PROJECT_NAME" || echo "（既に存在する場合はスキップして続行します）"

# 5. firebase.json / .firebaserc 初期化
firebase use "$PROJECT_NAME"

# 6. Firestore有効化 + ルールデプロイ
echo ""
echo "📄 Firestoreのセキュリティルールを書き込みます..."
cat > firestore.rules << 'RULES'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /machines/{machineId} {
      allow read: if true;
      allow create: if request.resource.data.maker is string
                    && request.resource.data.lat is number
                    && request.resource.data.lng is number;
      allow update: if request.resource.data.maker is string;
      allow delete: if false;
    }
  }
}
RULES

cat > firestore.indexes.json << 'IDX'
{
  "indexes": [],
  "fieldOverrides": []
}
IDX

cat > firebase.json << 'FBJSON'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": ".",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**", "setup.sh", "FIREBASE_SETUP.md"]
  }
}
FBJSON

firebase deploy --only firestore:rules

# 7. ウェブアプリ登録 + config取得
echo ""
echo "📱 ウェブアプリを登録し、設定値を取得します..."
APP_ID=$(firebase apps:create web "jihanki-map-web" --project "$PROJECT_NAME" --json | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  const j=JSON.parse(d); console.log(j.result.appId);
});")

firebase apps:sdkconfig web "$APP_ID" --project "$PROJECT_NAME" > firebase-config-output.txt

echo ""
echo "✅ 完了！ firebase-config-output.txt に設定値を書き出しました。"
echo "👉 次のステップ: この内容を vending-map.html 内の firebaseConfig に自動で反映します。"

# 8. vending-map.html へ自動反映
node << 'NODESCRIPT'
const fs = require('fs');
const out = fs.readFileSync('firebase-config-output.txt', 'utf8');
const match = out.match(/\{[\s\S]*\}/);
if(!match){ console.log("⚠ 設定値の自動抽出に失敗しました。firebase-config-output.txtを見て手動で貼ってください。"); process.exit(0); }

let html = fs.readFileSync('vending-map.html', 'utf8');
const configBlock = "const firebaseConfig = " + match[0].replace(/(\w+):/g, '"$1":') + ";";

html = html.replace(
  /const firebaseConfig = \{[\s\S]*?\};/,
  configBlock
);
fs.writeFileSync('vending-map.html', html);
console.log("✅ vending-map.html に firebaseConfig を自動反映しました。");
NODESCRIPT

# 9. Firestore Database本体の作成案内（CLIではロケーション選択が必要なため案内のみ）
echo ""
echo "⚠ 最後にもう1つだけ手動操作が必要です:"
echo "   https://console.firebase.google.com/project/$PROJECT_NAME/firestore を開き、"
echo "   「データベースの作成」→ ロケーション asia-northeast1 を選んで作成してください。"
echo "   （CLIからはロケーション選択ができないため、この1ステップだけは画面操作が必要です）"
echo ""
echo "=== すべて完了したら ==="
echo "python3 -m http.server 8000"
echo "http://localhost:8000/vending-map.html を開いて動作確認してください。"
