#!/usr/bin/env pwsh
# FocusBlocker Build Script

$FLUTTER_PATH = "C:\src\flutter\bin"
$PROJECT_PATH = "C:\Users\ksrih\Desktop\FocusBlock"

Write-Host "FocusBlocker - Build Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Step 1: Set PATH
Write-Host "[1/4] Setting up Flutter PATH..." -ForegroundColor Yellow
$env:PATH = "$FLUTTER_PATH;$env:PATH"
$env:FLUTTER_ROOT = "C:\src\flutter"
Write-Host "✓ Flutter path configured" -ForegroundColor Green

# Step 2: Navigate to project
Write-Host "[2/4] Navigating to project..." -ForegroundColor Yellow
Set-Location $PROJECT_PATH
Write-Host "✓ Project location: $PROJECT_PATH" -ForegroundColor Green

# Step 3: Get dependencies
Write-Host "[3/4] Fetching dependencies (flutter pub get)..." -ForegroundColor Yellow
& flutter pub get --verbose
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Error fetching dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# Step 4: Build APK
Write-Host "[4/4] Building debug APK..." -ForegroundColor Yellow
& flutter build apk --debug --verbose
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK Location: $PROJECT_PATH\build\app\outputs\apk\debug\app-debug.apk" -ForegroundColor Cyan
} else {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}
