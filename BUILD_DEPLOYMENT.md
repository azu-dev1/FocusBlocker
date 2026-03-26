# FocusBlocker - Build & Deployment Guide

## Prerequisites

- Flutter SDK 3.0.0+ ([flutter.dev](https://flutter.dev/docs/get-started/install))
- Android SDK API 21-34
- Kotlin 1.8+
- JDK 11+

### Verify Setup
```bash
flutter doctor
```

Should show:
- ✓ Flutter SDK location
- ✓ Android toolchain
- ✓ Android Studio
- ✓ Devices connected

## Project Setup (One-time)

### 1. Initialize Flutter Components
```bash
cd FocusBlocker

# Install dependencies
flutter pub get

# Configure Kotlin
flutter create --platforms=android .

# Verify Android module
ls -la android/
```

### 2. Update Gradle (if needed)
```bash
cd android

# Get latest Gradle wrapper
./gradlew wrapper --gradle-version=7.5  # Latest compatible version

cd ..
```

## Development Build

### Run on Connected Device

```bash
# List connected devices
flutter devices

# Run in debug mode
flutter run

# Run with verbose logging
flutter run -v

# Run on specific device
flutter run -d <device_id>
```

### Monitor Logs During Development

```bash
# Terminal 1: Run app
flutter run

# Terminal 2: Watch Kotlin logs
adb logcat | grep "FocusBlocker"

# Terminal 3: Watch all logs
adb logcat
```

## Debug Build APK

### Build Debug APK
```bash
flutter build apk --debug --target-platform=android-arm

# Output: build/app/outputs/apk/debug/app-debug.apk
```

### Install Debug APK
```bash
# Automatic install and run
flutter run

# Manual install
adb install -r build/app/outputs/apk/debug/app-debug.apk

# Launch after install
adb shell am start -n com.focusblocker/.MainActivity
```

## Release Build

### Generate Signing Key (One-time)

```bash
# Create keystore
keytool -genkey -v \
  -keystore ~/focusblocker.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias focusblocker-key

# Store in secure location - DO NOT LOSE
# You'll need this for updates
```

### Create Signing Configuration

Create `android/key.properties`:
```properties
storeFile=/path/to/focusblocker.jks
storePassword=<your_keystore_password>
keyAlias=focusblocker-key
keyPassword=<your_key_password>
```

### Build Release APK

```bash
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
# Size: ~50-100 MB (depending on dependencies)
```

### Build App Bundle (for Google Play)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Recommended for Play Store
```

## Testing Builds

### Test Debug Build
```bash
flutter run --debug -v
```

Verify:
- [ ] App starts without crashing
- [ ] All screens load correctly
- [ ] Permissions dialog works
- [ ] App selection shows installed apps
- [ ] Time picker works
- [ ] Blocking triggers correctly

### Test Release Build
```bash
# Build release
flutter build apk --release

# Install
adb install -r build/app/outputs/apk/release/app-release.apk

# Launch
adb shell am start -n com.focusblocker/.MainActivity

# Monitor
adb logcat | grep -i "focusblocker"
```

### Test on Multiple Devices

Supported API Levels:
- API 21-24 (Android 5.0-7.1): Basic support
- API 25-29 (Android 7.1-10): Full support
- API 30+ (Android 11+): Full support

```bash
# Test on all connected devices
flutter devices  # List devices
flutter run -d <device_id>  # Run on specific device
```

## Continuous Integration/CD Setup

### GitHub Actions Example

`.github/workflows/build.yml`:
```yaml
name: Build FocusBlocker

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v2
      with:
        name: app-release.apk
        path: build/app/outputs/apk/release/app-release.apk
```

## Distribution

### Direct Installation (Testing/Beta)

```bash
# Transfer APK to device
adb push build/app/outputs/apk/release/app-release.apk /sdcard/

# Or via file transfer app
# Or via email/cloud

# Install on device
adb install build/app/outputs/apk/release/app-release.apk
```

### Google Play Store

1. **Create Developer Account**
   - Go to [Google Play Console](https://play.google.com/console)
   - Create developer account ($25 one-time)
   - Set up store listing

2. **Prepare Store Listing**
   - App name: FocusBlocker
   - Short description (80 chars)
   - Full description
   - Screenshots (up to 8)
   - Feature graphic (1024x500)
   - Icon (512x512)
   - Category: Productivity
   - Rating: 12+ (content rating)

3. **Upload App Bundle**
   ```bash
   flutter build appbundle --release
   ```
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Internal testing → Closed testing → Production

4. **Review Process**
   - Google Play automated review: 1-2 hours
   - Approval checks for:
     - Accessibility Service misuse
     - Privacy policy
     - Permissions appropriateness
     - Policy compliance

5. **Release**
   - Roll out: 0% → 100% gradually
   - Staged rollout prevents widespread issues

### APK Distribution (Other Stores)

For F-Droid, Amazon Appstore, etc.:

```bash
# Rename for distribution
cp build/app/outputs/apk/release/app-release.apk FocusBlocker_1.0.0.apk

# Sign independently if needed
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/focusblocker.jks FocusBlocker_1.0.0.apk focusblocker-key
```

## Update Management

### Version Bumping

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Major.Minor.Patch+Build
```

Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    versionCode = 2      // Increment by 1 for each release
    versionName = "1.0.1"
}
```

### Semantic Versioning
- **Major (1.0.0)**: Breaking changes
- **Minor (1.1.0)**: New features, backward compatible
- **Patch (1.0.1)**: Bug fixes only

## Performance Optimization

### Reduce APK Size

```bash
# Current size
du -h build/app/outputs/apk/release/app-release.apk

# Enable ProGuard
android/app/build.gradle:
buildTypes {
    release {
        minifyEnabled true
        proguardFiles getDefaultProguardFile(
            'proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Create `android/app/proguard-rules.pro`:
```
# Flutter
-keep class io.flutter.** { *; }
-keep class com.focusblocker.** { *; }

# Keep custom accessibility service
-keep class com.focusblocker.CustomAccessibilityService { *; }
```

## Troubleshooting Build Issues

### Issue: "gradlew not executable"
```bash
chmod +x android/gradlew
```

### Issue: "Kotlin not found"
```bash
flutter pub get
cd android && ./gradlew clean && cd ..
```

### Issue: "Gradle sync failed"
```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

### Issue: "Android NDK not found"
```bash
# Flutter will auto-download NDK
flutter doctor --android-licenses

# Accept all licenses
yes | flutter doctor --android-licenses
```

### Issue: "Port 8888 already in use"
```bash
# Close running instances
adb kill-server
adb start-server
```

### Issue: "Insufficient storage"
```bash
# Check device storage
adb shell df /data

# Free up space
adb shell pm clear <package>  # Clear app cache

# Or on device
Settings → Storage → Clear cache
```

## Performance Testing

### Measure Build Time
```bash
time flutter build apk --release
```

Typical times:
- Clean build: 2-5 minutes
- Incremental: 30-60 seconds
- Release: 3-10 minutes

### Monitor APK Size
```bash
# Analyze APK contents
cd build/app/outputs/apk/release/
unzip -l app-release.apk | head -20
du -h app-release.apk

# Typical breakdown
# - Flutter engine: 20 MB
# - Dependencies: 10 MB
# - Resources: 5 MB
# - Code: 15 MB
```

### Optimize Build

Add to `android/app/build.gradle`:
```gradle
android {
    // ...
    bundle {
        language.enableSplit = true
        density.enableSplit = true
        abi.enableSplit = true
    }
}
```

## Debugging Build Artifacts

### Inspect APK Manifest
```bash
# Extract manifest
unzip -p build/app/outputs/apk/release/app-release.apk AndroidManifest.xml > manifest.xml

# Format and view
cat manifest.xml | sed 's/></>\n</g'
```

### Check Built Dex Files
```bash
# List dex files
unzip -l build/app/outputs/apk/release/app-release.apk | grep dex

# Analyze dex
cd build/app/outputs/apk/release
unzip app-release.apk classes.dex
cd ../../../..
```

### Verify Signing
```bash
# Check signature
jarsigner -verify -verbose build/app/outputs/apk/release/app-release.apk

# Should show: "jar verified"
```

## Version Management

### Track Builds
```bash
# Tag releases
git tag v1.0.0
git push origin v1.0.0

# Create changelog
echo "v1.0.0 - Initial Release" > CHANGELOG.md
echo "- Real app blocking with AccessibilityService" >> CHANGELOG.md
echo "- Multi-app selection and time scheduling" >> CHANGELOG.md
```

### Release Checklist
- [ ] Update version in pubspec.yaml
- [ ] Update build number in build.gradle
- [ ] Update CHANGELOG.md
- [ ] Test on multiple devices
- [ ] All logs clean (no errors/warnings)
- [ ] Permissions all necessary
- [ ] Accessibility service works
- [ ] Blocking functionality verified
- [ ] Build APK/Bundle
- [ ] Sign APK
- [ ] Create git tag
- [ ] Push to repository

## Rollback Procedure

If release has issues:

1. **Revert Code**
   ```bash
   git revert <commit_hash>
   ```

2. **Rebuild Previous Version**
   ```bash
   git checkout <previous_tag>
   flutter build apk --release
   ```

3. **Re-upload**
   - Google Play: Create new update with reverted code
   - APK sites: Remove problematic version

## Deployment Checklist

### Before Release
- [ ] Code reviewed
- [ ] All tests passing
- [ ] No compiler warnings
- [ ] No Lint errors
- [ ] Performance tested
- [ ] Battery impact measured
- [ ] All permissions justified
- [ ] Privacy policy prepared
- [ ] Screenshots prepared
- [ ] Store listing written

### During Release
- [ ] Build succeeds
- [ ] APK/Bundle signed correctly
- [ ] File size acceptable
- [ ] Uploaded to store
- [ ] Visibility set correctly
- [ ] Rollout percentage set (start at 5%)

### After Release
- [ ] Monitor crash reports
- [ ] Check download stats
- [ ] Read user reviews
- [ ] Monitor rating changes
- [ ] Check support emails

## Long-term Maintenance

### Monthly Tasks
- Review crash reports
- Update dependencies
- Check Flutter updates
- Build sample on real device

### Quarterly Tasks
- Full security audit
- Performance optimization
- User feedback review
- Feature prioritization

### Annually
- Update all SDKs
- Increase target API version
- Review and refactor code
- Plan major updates
