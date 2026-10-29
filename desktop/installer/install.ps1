$ErrorActionPreference = 'Stop'

$installRoot = Join-Path $env:LOCALAPPDATA 'AutoYaad CMS'
$sourceWebZip = Join-Path $PSScriptRoot 'cms_web.zip'
$sourceLauncher = Join-Path $PSScriptRoot 'launch.ps1'

New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
$installedWeb = Join-Path $installRoot 'cms_web'
New-Item -ItemType Directory -Force -Path $installedWeb | Out-Null
Expand-Archive -LiteralPath $sourceWebZip -DestinationPath $installedWeb -Force
Copy-Item -LiteralPath $sourceLauncher -Destination (Join-Path $installRoot 'launch.ps1') -Force

$powershell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AutoYaad CMS.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershell
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installRoot\launch.ps1`""
$shortcut.WorkingDirectory = $installRoot
$shortcut.IconLocation = "$env:WINDIR\System32\shell32.dll,13"
$shortcut.Description = 'AutoYaad CMS — publish, approve and mark vehicles sold'
$shortcut.Save()

$startMenu = Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\AutoYaad CMS.lnk'
$startMenuShortcut = $shell.CreateShortcut($startMenu)
$startMenuShortcut.TargetPath = $powershell
$startMenuShortcut.Arguments = $shortcut.Arguments
$startMenuShortcut.WorkingDirectory = $installRoot
$startMenuShortcut.IconLocation = $shortcut.IconLocation
$startMenuShortcut.Description = $shortcut.Description
$startMenuShortcut.Save()

Start-Process -WindowStyle Hidden -FilePath $powershell -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden',
  '-File', (Join-Path $installRoot 'launch.ps1')
)
