# リリース用バージョン更新スクリプト
# 使い方:  pwsh ./bump-version.ps1
# version.json / vending-map.html(APP_VERSION) / sw.js(VERSION) の3か所を
# 同じバージョン文字列（YYYY.MM.DD.N）に一括更新する。
# 同じ日に複数回リリースする場合は末尾の番号が自動で +1 される。

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$verFile  = Join-Path $root 'version.json'
$htmlFile = Join-Path $root 'vending-map.html'
$swFile   = Join-Path $root 'sw.js'

# 現在のバージョンを取得
$cur = ''
if (Test-Path $verFile) {
    try { $cur = (Get-Content $verFile -Raw | ConvertFrom-Json).version } catch {}
}

$today = Get-Date -Format 'yyyy.MM.dd'
$seq = 1
if ($cur -match "^$([regex]::Escape($today))\.(\d+)$") {
    $seq = [int]$Matches[1] + 1
}
$new = "$today.$seq"

# version.json
Set-Content -Path $verFile -Value ('{ "version": "' + $new + '" }') -Encoding utf8 -NoNewline

# vending-map.html  ->  const APP_VERSION = '...';
$html = Get-Content $htmlFile -Raw
$html = [regex]::Replace($html, "const APP_VERSION = '[^']*';", "const APP_VERSION = '$new';")
Set-Content -Path $htmlFile -Value $html -Encoding utf8 -NoNewline

# sw.js  ->  const VERSION = '...';
$sw = Get-Content $swFile -Raw
$sw = [regex]::Replace($sw, "const VERSION = '[^']*';", "const VERSION = '$new';")
Set-Content -Path $swFile -Value $sw -Encoding utf8 -NoNewline

Write-Host "バージョンを $cur -> $new に更新しました。"
Write-Host "次に:  git add -A; git commit -m 'release $new'; git push"
