$port = 8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$port/")
try {
    $listener.Start()
} catch {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Write-Host "Right-click PowerShell -> 'Run as Administrator' and try again." -ForegroundColor Yellow
    exit 1
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match 'Wi-Fi' } | Select-Object -First 1).IPAddress
Write-Host ""
Write-Host "=== Jihanki Map Server ===" -ForegroundColor Green
Write-Host "PC:      http://localhost:$port/vending-map.html" -ForegroundColor Cyan
Write-Host "iPhone:  http://${ip}:$port/vending-map.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

$mime = @{
    '.html'='text/html; charset=utf-8'; '.js'='application/javascript'
    '.css'='text/css'; '.json'='application/json'
    '.png'='image/png'; '.jpg'='image/jpeg'; '.ico'='image/x-icon'
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.LocalPath
        if ($path -eq '/') { $path = '/vending-map.html' }
        $filePath = Join-Path $root ($path -replace '/', '\')

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            Write-Host "200 $path" -ForegroundColor Green
        } else {
            $ctx.Response.StatusCode = 404
            $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $ctx.Response.ContentLength64 = $body.Length
            $ctx.Response.OutputStream.Write($body, 0, $body.Length)
            Write-Host "404 $path" -ForegroundColor Red
        }
        $ctx.Response.OutputStream.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}
