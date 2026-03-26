$androidHome = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$tempZip = "$env:TEMP\cmdline-tools.zip"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Android SDK Setup for Flutter" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target: $androidHome" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $androidHome)) {
    New-Item -ItemType Directory -Path $androidHome -Force | Out-Null
    Write-Host "Created Android SDK directory" -ForegroundColor Green
}

Write-Host "Downloading Android cmdline-tools..." -ForegroundColor Yellow
Write-Host ""

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($cmdlineToolsUrl, $tempZip)

Write-Host "Download complete!" -ForegroundColor Green
Write-Host ""

Write-Host "Extracting files..." -ForegroundColor Yellow
$extractTemp = "$env:TEMP\cmdline-tools-extract"
Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $tempZip -DestinationPath $extractTemp -Force

$cmdlineSource = Get-ChildItem $extractTemp -Filter "cmdline-tools" -Directory | Select-Object -First 1
if ($cmdlineSource) {
    $cmdlineDestination = "$androidHome\cmdline-tools\latest"
    Remove-Item $cmdlineDestination -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "$androidHome\cmdline-tools" -Force -ErrorAction SilentlyContinue | Out-Null
    Move-Item -Path $cmdlineSource.FullName -Destination $cmdlineDestination -Force
}

Write-Host "Extraction complete!" -ForegroundColor Green
Write-Host ""

$env:ANDROID_HOME = $androidHome
$env:ANDROID_SDK_ROOT = $androidHome
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidHome, "User")

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Android SDK setup complete!" -ForegroundColor Green
Write-Host "====================================="
