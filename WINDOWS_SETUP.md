# FocusBlocker - Windows Setup Instructions

## ⚠️ Flutter SDK Not Found

Flutter is not installed on your system. Follow these steps to set up your development environment:

## Step 1: Install Flutter SDK

### Option A: Download from flutter.dev (Recommended)

1. Go to https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK (latest stable)
3. Extract to a folder (e.g., `C:\src\flutter`)

### Option B: Use Git (Alternative)

```powershell
# Create folder for Flutter
mkdir C:\src
cd C:\src

# Clone Flutter repository
git clone https://github.com/flutter/flutter.git -b stable

# The flutter directory is now: C:\src\flutter
```

## Step 2: Add Flutter to PATH

1. Open Environment Variables:
   - Press `Win + X` → System
   - Click "Advanced system settings"
   - Click "Environment Variables"

2. Under "User variables", click "New":
   - Variable name: `FLUTTER_HOME`
   - Variable value: `C:\src\flutter` (or wherever you extracted Flutter)

3. Edit the `Path` variable:
   - Add: `C:\src\flutter\bin`
   - Add: `C:\src\flutter\bin\cache\dart-sdk\bin`

4. Click OK and restart PowerShell

## Step 3: Verify Installation

```powershell
# Restart PowerShell first!
flutter doctor
```

Expected output should show:
- ✓ Flutter SDK
- ✓ Android toolchain
- ✓ Android SDK

## Step 4: Install Android SDK (if needed)

If flutter doctor shows ✗ Android toolchain:

```powershell
# Let Flutter download and install Android SDK
flutter doctor --android-licenses
yes | flutter doctor --android-licenses

# Try again
flutter doctor
```

## Step 5: Accept Android Licenses

```powershell
# Accept all Android SDK licenses
sdkmanager --licenses
# Type 'y' for all licenses
```

## Step 6: Install Project Dependencies

```powershell
cd C:\Users\ksrih\Desktop\FocusBlock
flutter pub get
```

## Step 7: Build the Project

### Build Debug APK
```powershell
flutter build apk --debug
```

### Or Build Release APK
```powershell
flutter build apk --release
```

The APK will be at:
- Debug: `build/app/outputs/apk/debug/app-debug.apk`
- Release: `build/app/outputs/apk/release/app-release.apk`

## Troubleshooting

### Issue: After setting PATH, flutter still not found
- Restart your terminal completely (close and reopen PowerShell)
- Or use the full path: `C:\src\flutter\bin\flutter doctor`

### Issue: Android SDK not found
```powershell
flutter doctor --android-licenses
yes | flutter doctor --android-licenses
```

### Issue: Android toolchain issues
```powershell
flutter clean
flutter pub get
# Try again
```

### Issue: Java not found
Download and install Java 11+:
- https://adoptium.net/ (Temurin)
- Add JAVA_HOME to environment variables

## Quick Reference

```powershell
# After Flutter is installed:
cd C:\Users\ksrih\Desktop\FocusBlock

# Install dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run on connected device
flutter run

# Clean build
flutter clean
flutter pub get
flutter build apk --debug
```

**Next:** Once Flutter is installed and `flutter doctor` shows all ✓, return to this folder and run:
```powershell
cd C:\Users\ksrih\Desktop\FocusBlock
flutter pub get
flutter build apk --debug
```
