@echo off
REM Android SDK Download and Setup
REM This installs the minimum required Android SDK for Flutter

set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%

echo.
echo =====================================
echo Android SDK Setup
echo =====================================
echo.
echo Target: %ANDROID_HOME%
echo.

REM Create SDK directory
if not exist "%ANDROID_HOME%" (
    mkdir "%ANDROID_HOME%"
    echo ✓ Created SDK directory
) else (
    echo ✓ SDK directory exists
)

REM Download cmdline-tools (if PowerShell is available)
echo.
echo Downloading Android cmdline-tools...
echo (This may take a few minutes)
echo.

powershell -Command "^ ^
$url = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'; ^ ^
$output = '%TEMP%\cmdline-tools.zip'; ^ ^
Write-Host 'Downloading from: $url'; ^ ^
try { ^ ^
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^ ^
  (New-Object System.Net.WebClient).DownloadFile($url, $output); ^ ^
  Write-Host 'Download complete'; ^ ^
  Write-Host 'Extracting...'; ^ ^
  Expand-Archive -Path $output -DestinationPath '%ANDROID_HOME%\cmdline-tools' -Force; ^ ^
  Write-Host 'Extraction complete'; ^ ^
} catch { ^ ^
  Write-Host 'Download failed: $_'; ^ ^
  Exit 1; ^ ^
} ^ ^
"

if errorlevel 1 (
    echo ERROR: Failed to download Android cmdline-tools
    echo.
    echo You need to install Android SDK manually:
    echo 1. Go to https://developer.android.com/studio
    echo 2. Download Android Studio 
    echo 3. Install and let it set up Android SDK
    echo 4. Then try building again
    echo.
    pause
    exit /b 1
)

echo ✓ Android cmdline-tools installed

REM Set environment variable
setx ANDROID_HOME "%ANDROID_HOME%"
setx ANDROID_SDK_ROOT "%ANDROID_HOME%"

echo ✓ Environment variables set
echo.
echo Setup complete!
echo Please restart Flutter build process.
echo.
pause
