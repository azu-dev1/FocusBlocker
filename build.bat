@echo off
REM Set PATH with Flutter
set PATH=C:\src\flutter\bin;%PATH%

REM Navigate to project
cd /d C:\Users\ksrih\Desktop\FocusBlock

REM Get dependencies
echo Fetching Flutter dependencies...
call flutter pub get

REM Build APK
echo Building debug APK...
call flutter build apk --debug

pause
