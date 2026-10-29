$ErrorActionPreference = 'Stop'

$webRoot = Join-Path $PSScriptRoot 'cms_web'
$listener = New-Object System.Net.HttpListener
$portProbe = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
$portProbe.Start()
$port = $portProbe.LocalEndpoint.Port
$portProbe.Stop()
$prefix = "http://127.0.0.1:$port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

$browserCandidates = @(
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
)
$browser = $browserCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $browser) {
  $browser = (Get-Command msedge.exe, chrome.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
}
if (-not $browser) {
  Start-Process $prefix
} else {
  $profile = Join-Path $env:LOCALAPPDATA 'AutoYaad CMS\browser-profile-v2'
  New-Item -ItemType Directory -Force -Path $profile | Out-Null
  Start-Process -FilePath $browser -ArgumentList @(
    "--app=$prefix", "--user-data-dir=$profile", '--no-first-run', '--no-default-browser-check'
  )
}

$contentTypes = @{
  '.css' = 'text/css; charset=utf-8'; '.html' = 'text/html; charset=utf-8';
  '.ico' = 'image/x-icon'; '.js' = 'text/javascript; charset=utf-8';
  '.json' = 'application/json; charset=utf-8'; '.png' = 'image/png';
  '.svg' = 'image/svg+xml'; '.ttf' = 'font/ttf'; '.wasm' = 'application/wasm';
  '.webp' = 'image/webp'
}
$rootPath = (Resolve-Path $webRoot).Path.TrimEnd('\')

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
      $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath).TrimStart('/')
      if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
      $filePath = [IO.Path]::GetFullPath((Join-Path $rootPath $relative))
      if (-not $filePath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
        $context.Response.StatusCode = 403
        $context.Response.Close()
        continue
      }
      if ((Test-Path -LiteralPath $filePath -PathType Container) -or -not (Test-Path -LiteralPath $filePath)) {
        if ($relative -notmatch '\.') { $filePath = Join-Path $rootPath 'index.html' }
      }
      if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        $context.Response.StatusCode = 404
        $context.Response.Close()
        continue
      }
      $bytes = [IO.File]::ReadAllBytes($filePath)
      $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
      $context.Response.ContentType = if ($contentTypes.ContainsKey($extension)) { $contentTypes[$extension] } else { 'application/octet-stream' }
      $context.Response.Headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
      $context.Response.Headers['Pragma'] = 'no-cache'
      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } finally {
      $context.Response.Close()
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
