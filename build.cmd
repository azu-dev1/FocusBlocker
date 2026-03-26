@echo off
REM FocusBlocker Build Script
REM This script builds the Flutter app APK

setlocal enabledelayedexpansion

REM Set paths
set FLUTTER_HOME=C:\src\flutter
set FLUTTER_BIN=%FLUTTER_HOME%\bin
set PROJECT_PATH=C:\Users\ksrih\Desktop\FocusBlock

REM Add Flutter to PATH
set PATH=%FLUTTER_BIN%;%PATH%

REM Change to project directory
cd /d "%PROJECT_PATH%"

REM Echo status
echo.
echo =====================================
echo FocusBlocker - Build Script
echo =====================================
echo.

REM Check if flutter exists
if not exist "%FLUTTER_BIN%\flutter.bat" (
    echo ERROR: Flutter not found at %FLUTTER_BIN%
    echo.
    pause
    exit /b 1
)

echo [1/4] Flutter found at: %FLUTTER_HOME%
echo.

REM Step 1: Flutter Doctor
echo [2/4] Running flutter doctor...
call "%FLUTTER_BIN%\flutter.bat" doctor
if errorlevel 1 (
    echo ERROR: flutter doctor failed
    pause
    exit /b 1
)
echo.

REM Step 2: Get dependencies
echo [3/4] Installing dependencies (flutter pub get)...
call "%FLUTTER_BIN%\flutter.bat" pub get
if errorlevel 1 (
    echo ERROR: flutter pub get failed
    pause
    exit /b 1
)
echo.

REM Step 3: Build APK
echo [4/4] Building debug APK...
call "%FLUTTER_BIN%\flutter.bat" build apk --debug
if errorlevel 1 (
    echo ERROR: flutter build apk failed
    echo.
    echo Trying to build release APK instead...
    call "%FLUTTER_BIN%\flutter.bat" build apk --release
    if errorlevel 1 (
        echo ERROR: Build failed
        pause
        exit /b 1
    )
)

echo.
echo =====================================
echo BUILD SUCCESSFUL!
echo =====================================
echo.
echo APK Output:
echo %PROJECT_PATH%\build\app\outputs\apk\debug\app-debug.apk
echo (or release version in apk\release\)
echo.
pause
exit /b 0
