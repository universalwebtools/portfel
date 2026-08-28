$ErrorActionPreference = 'Stop'
$port = 4173
$root = Join-Path $PSScriptRoot 'aplikacja'

if (-not (Test-Path (Join-Path $root 'index.html'))) {
    throw 'Brakuje folderu aplikacja lub pliku index.html.'
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
try {
    $listener.Start()
} catch {
    $port = 4174
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
    $listener.Start()
}

$url = "http://localhost:$port/"
Write-Host ''
Write-Host 'WSPÓLNY PORTFEL - WERSJA TESTOWA' -ForegroundColor Green
Write-Host "Aplikacja działa pod adresem: $url"
Write-Host 'Nie zamykaj tego okna podczas testowania.' -ForegroundColor Yellow
Write-Host 'Aby zakończyć, zamknij to okno lub naciśnij Ctrl+C.'
Write-Host ''
Start-Process $url

$mime = @{
    '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8';
    '.css'='text/css; charset=utf-8'; '.json'='application/json; charset=utf-8';
    '.webmanifest'='application/manifest+json'; '.svg'='image/svg+xml';
    '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg';
    '.ico'='image/x-icon'; '.woff2'='font/woff2'; '.wasm'='application/wasm'
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 4096, $true)
            $requestLine = $reader.ReadLine()
            while ($reader.ReadLine()) { }
            $rawPath = if ($requestLine -match '^\S+\s+([^\s?]+)') { $matches[1] } else { '/' }
            $relative = [Uri]::UnescapeDataString($rawPath).TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
            if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
            $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not $candidate.StartsWith([IO.Path]::GetFullPath($root)) -or -not (Test-Path $candidate -PathType Leaf)) {
                $candidate = Join-Path $root 'index.html'
            }
            $body = [IO.File]::ReadAllBytes($candidate)
            $ext = [IO.Path]::GetExtension($candidate).ToLowerInvariant()
            $contentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
            $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
            $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($body, 0, $body.Length)
        } catch { } finally { $client.Close() }
    }
} finally {
    $listener.Stop()
}
