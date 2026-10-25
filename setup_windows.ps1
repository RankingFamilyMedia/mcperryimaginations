$ErrorActionPreference = "Stop"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter is not available in PATH." }
flutter create --platforms=android --org com.mcperryimaginations --project-name autoyaad_ghana .
flutter pub get
Write-Host "Next run: firebase login, firebase use YOUR_PROJECT_ID, and flutterfire configure" -ForegroundColor Yellow
Write-Host "Copy google-services.json into android\app, deploy Firebase rules, then run flutter analyze and flutter run." -ForegroundColor Green
