$port = 8091
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = [System.Net.HttpListener]::new()
# localhost binding does NOT require admin privileges
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Preview server on http://localhost:$port/vending-map.html"

$mime = @{
    '.html'='text/html; charset=utf-8'; '.js'='application/javascript'
    '.css'='text/css'; '.json'='application/json'
    '.png'='image/png'; '.jpg'='image/jpeg'; '.ico'='image/x-icon'
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        try {
            $path = $ctx.Request.Url.LocalPath
            if ($path -eq '/') { $path = '/vending-map.html' }
            $filePath = Join-Path $root ($path -replace '/', '\')
            $isHead = $ctx.Request.HttpMethod -eq 'HEAD'

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                if ($isHead) {
                    $ctx.Response.ContentLength64 = $bytes.Length
                    $ctx.Response.Close()
                } else {
                    # Close(byte[], bool) sets Content-Length and writes body safely
                    $ctx.Response.Close($bytes, $true)
                }
            } else {
                $ctx.Response.StatusCode = 404
                $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                $ctx.Response.Close($body, $true)
            }
        } catch {
            try { $ctx.Response.Abort() } catch {}
        }
    }
} finally {
    $listener.Stop()
}
