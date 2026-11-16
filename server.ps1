# RightPick 職場遊樂場 — 後備本機伺服器（Windows PowerShell，唔需要 Python）
# 用 TcpListener 直接服務資料夾，避開 HttpListener 嘅權限問題。
param([int]$Port = 8080)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.wasm' = 'application/wasm'
  '.task' = 'application/octet-stream'
  '.svg'  = 'image/svg+xml'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.ico'  = 'image/x-icon'
  '.woff2' = 'font/woff2'
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "RightPick Arcade -> http://localhost:$Port/"

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $client.ReceiveTimeout = 5000
    $client.SendTimeout = 30000
    $stream = $client.GetStream()

    # ---- 讀取 HTTP request 標頭 ----
    $buf = New-Object byte[] 8192
    $sb = New-Object System.Text.StringBuilder
    $headerEnd = -1
    while ($headerEnd -lt 0) {
      $n = $stream.Read($buf, 0, $buf.Length)
      if ($n -le 0) { break }
      [void]$sb.Append([System.Text.Encoding]::ASCII.GetString($buf, 0, $n))
      $headerEnd = $sb.ToString().IndexOf("`r`n`r`n")
      if ($sb.Length -gt 65536) { break }
    }
    $header = $sb.ToString()
    $firstLine = ($header -split "`r`n")[0]
    $parts = $firstLine -split ' '
    $urlPath = '/'
    if ($parts.Length -ge 2) { $urlPath = $parts[1] }
    $urlPath = $urlPath.Split('?')[0]
    $urlPath = [System.Uri]::UnescapeDataString($urlPath)
    if ($urlPath -eq '/') { $urlPath = '/index.html' }

    $full = [System.IO.Path]::GetFullPath((Join-Path $root ($urlPath.TrimStart('/') -replace '/', '\')))

    # ---- 防止跳出資料夾 ----
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      $body = [System.Text.Encoding]::UTF8.GetBytes('403 Forbidden')
      $hdr = "HTTP/1.1 403 Forbidden`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $stream.Write([System.Text.Encoding]::ASCII.GetBytes($hdr), 0, $hdr.Length)
      $stream.Write($body, 0, $body.Length)
      continue
    }

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
      $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $hdr = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $stream.Write([System.Text.Encoding]::ASCII.GetBytes($hdr), 0, $hdr.Length)
      $stream.Write($body, 0, $body.Length)
      continue
    }

    $ext = [System.IO.Path]::GetExtension($full).ToLower()
    $type = $mime[$ext]
    if (-not $type) { $type = 'application/octet-stream' }
    $len = (Get-Item -LiteralPath $full).Length
    $hdr = "HTTP/1.1 200 OK`r`nContent-Type: $type`r`nContent-Length: $len`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
    $hdrBytes = [System.Text.Encoding]::ASCII.GetBytes($hdr)
    $stream.Write($hdrBytes, 0, $hdrBytes.Length)

    $fs = [System.IO.File]::OpenRead($full)
    try { $fs.CopyTo($stream, 65536) } finally { $fs.Dispose() }
    $stream.Flush()
  } catch {
    # 忽略單一連線錯誤，繼續服務
  } finally {
    try { $client.Close() } catch {}
  }
}
