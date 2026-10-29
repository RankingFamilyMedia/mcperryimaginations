$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$payload = Join-Path $projectRoot 'build\cms-installer-payload'
$output = Join-Path $projectRoot 'build\desktop\AutoYaad-CMS-Installer.exe'
$sed = Join-Path $payload 'AutoYaad-CMS.sed'

if (-not (Test-Path (Join-Path $projectRoot 'build\web\index.html'))) {
  throw 'Build the CMS web release first: flutter build web --release --dart-define=CMS_MODE=true'
}

Remove-Item -LiteralPath $payload -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $payload,(Split-Path $output) | Out-Null
Compress-Archive -Path (Join-Path $projectRoot 'build\web\*') -DestinationPath (Join-Path $payload 'cms_web.zip') -CompressionLevel Optimal -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install.cmd'),(Join-Path $PSScriptRoot 'install.ps1'),(Join-Path $PSScriptRoot 'launch.ps1') -Destination $payload -Force

$files = Get-ChildItem -LiteralPath $payload -Recurse -File | Where-Object { $_.FullName -ne $sed }
$stringLines = [System.Collections.Generic.List[string]]::new()
$sourceLines = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $files.Count; $i++) {
  $relative = $files[$i].FullName.Substring($payload.Length + 1).Replace('\', '/')
  $name = "FILE$i"
  $stringLines.Add(('{0}="{1}"' -f $name, $relative))
  $sourceLines.Add("%$name%=")
}

$target = $output
$payloadPath = $payload
$sedText = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=
FinishMessage=%FinishMessage%
TargetName=$target
FriendlyName=AutoYaad CMS
AppLaunched=install.cmd
PostInstallCmd=<None>
SourceFiles=SourceFiles

[Strings]
InstallPrompt=Installing AutoYaad CMS...
FinishMessage=AutoYaad CMS was installed. A desktop shortcut was created.
$($stringLines -join "`r`n")

[SourceFiles]
SourceFiles0=$payloadPath

[SourceFiles0]
$($sourceLines -join "`r`n")
"@
Set-Content -LiteralPath $sed -Value $sedText -Encoding ASCII

& "$env:WINDIR\System32\iexpress.exe" /N /Q $sed
for ($attempt = 0; $attempt -lt 60 -and -not (Test-Path -LiteralPath $output); $attempt++) {
  Start-Sleep -Seconds 1
}
if (-not (Test-Path -LiteralPath $output)) {
  throw "IExpress did not create $output"
}
Get-Item -LiteralPath $output | Select-Object FullName,Length,LastWriteTime
