# FocusBlocker - Troubleshooting Guide

## Problem: Blocking Doesn't Work

### Symptom: Selected apps open normally without blocking

#### Diagnosis Steps
1. **Check Accessibility Service Status**
   ```bash
   adb shell settings get secure enabled_accessibility_services
   ```
   Should contain: `com.focusblocker/.CustomAccessibilityService`

2. **Check Shared Preferences**
   ```bash
   adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml
   ```
   Should show:
   ```xml
   <set name="blocked_packages">
       <string>com.example.app</string>
   </set>
   <long name="start_time" value="1234567890"/>
   <long name="end_time" value="1234567891"/>
   <boolean name="is_active" value="true" />
   ```

3. **Check Logcat**
   ```bash
   adb logcat | grep FocusBlocker
   ```
   Look for:
   - `CustomAccessibilityService Connected` - Service started
   - `Blocking app: com.example.app` - Block triggered
   - Errors or exceptions

#### Solutions

**Solution 1: Re-enable Accessibility Service**
1. Settings → Accessibility → Services
2. Find FocusBlocker
3. Toggle OFF
4. Toggle ON
5. Grant permissions when prompted
6. Return to app

**Solution 2: Check Time Window**
- Current time must be BETWEEN start and end time
- Check device clock is correct
- Verify times in app: Home → Configure Time

**Solution 3: Verify App Name**
- App name must match exactly (package name)
- Example: `com.facebook.katana` not just "Facebook"
- Check in app: Home → Select Apps → already shows correct names

**Solution 4: Clear App Data**
```bash
adb shell pm clear com.focusblocker
```
Then:
1. Reopen app
2. Reconfigure from scratch
3. Re-enable Accessibility Service

## Problem: Service Gets Killed

### Symptom: Blocking works for few minutes then stops

#### Diagnosis Steps
1. **Check Service Status**
   ```bash
   adb shell ps | grep focusblocker
   ```
   If nothing appears, service was killed

2. **Check Battery Stats**
   ```bash
   adb shell dumpsys batterystats | grep com.focusblocker
   ```

3. **Monitor Service Deaths**
   ```bash
   adb logcat | grep "AppBlockingService Destroyed"
   ```

#### Solutions

**Solution 1: Disable Battery Optimization**
1. Settings → Battery → Battery Optimization
2. Switch dropdown to "All apps"
3. Find FocusBlocker
4. Tap it
5. Select "Don't optimize"
6. Confirm

**Solution 2: Whitelist from Task Killer Apps**
If using CCleaner, AVG Clean, etc.:
1. Open app
2. Add FocusBlocker to whitelist
3. Configure to never kill this app

**Solution 3: Disable MIUI/OneUI Optimization**
For Xiaomi/Samsung devices:
1. Settings → Apps → Permissions → Other permissions
2. Find "Display pop-up window" or similar
3. Enable for FocusBlocker
4. Settings → Battery → Power Saving Modes → Smart Power Saving
5. Add FocusBlocker to exception list

**Solution 4: Increase Polling Interval**
Edit `android/app/src/main/kotlin/com/focusblocker/AppBlockingService.kt`:
```kotlin
// Change from 5 seconds to 1 second
Thread.sleep(1000) // Was 5000
```

## Problem: Accessibility Service Won't Enable

### Symptom: Settings → Accessibility shows no FocusBlocker option

#### Diagnosis Steps
1. **Verify Service Declaration**
   ```bash
   adb shell dumpsys accessibility
   ```
   Should list `com.focusblocker/.CustomAccessibilityService`

2. **Check Installation**
   ```bash
   adb shell pm list packages | grep focusblocker
   ```
   Should show: `package:com.focusblocker`

3. **Check Manifest**
   ```bash
   adb shell dumpsys package com.focusblocker | grep Service
   ```

#### Solutions

**Solution 1: Rebuild and Reinstall**
```bash
flutter clean
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

**Solution 2: Check Manifest**
Verify in `android/app/src/main/AndroidManifest.xml`:
```xml
<service
    android:name=".CustomAccessibilityService"
    android:enabled="true"
    android:exported="true"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
```

**Solution 3: Grant Permissions**
```bash
adb shell pm grant com.focusblocker android.permission.BIND_ACCESSIBILITY_SERVICE
adb shell pm grant com.focusblocker android.permission.PACKAGE_USAGE_STATS
```

## Problem: Blocking Screen Stuck

### Symptom: Cannot dismiss blocking screen, phone frozen

#### Emergency Solutions

**Solution 1: Wait for Timer (if Strict Mode)**
- Blocking screen will auto-dismiss when timer expires
- Check remaining time shown on screen

**Solution 2: Force Restart Device**
- Hold Power button 10+ seconds
- Select Power Off
- Turn back on after 5 seconds

**Solution 3: Uninstall via ADB**
```bash
adb uninstall com.focusblocker
```

## Problem: Crashes on Startup

### Symptom: App crashes immediately upon opening

#### Diagnosis Steps
1. **Check Logcat**
   ```bash
   adb logcat | grep "AndroidRuntime\|FATAL\|Fatal"
   ```

2. **Look for specific errors**:
   - ClassNotFoundException
   - NullPointerException
   - Resources not found

#### Solutions

**Solution 1: Check Dependencies**
```bash
flutter pub get
flutter packages pub outdated
```

**Solution 2: Clean Build**
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
flutter run
```

**Solution 3: Gradle Cache Issue**
```bash
cd android
./gradlew clean
cd ..
flutter build apk --debug
```

## Problem: App Runs But UI Broken

### Symptom: UI shows errors, buttons don't work, missing text

#### Diagnosis Steps
1. Check Logcat for layout errors
2. Verify all string resources exist

#### Solutions

**Solution 1: Rebuild**
```bash
flutter clean
flutter run
```

**Solution 2: Check strings.xml**
```bash
adb shell cat /data/local/tmp/package.txt | grep strings
```

**Solution 3: Update pubspec.yaml**
```bash
flutter pub upgrade
flutter pub get
```

## Problem: Cannot Select Apps

### Symptom: App list is empty or shows only one app

#### Diagnosis Steps
1. **Check Installed Apps**
   ```bash
   adb shell cmd package list packages -3
   ```
   (Shows third-party apps)

2. **Check Permissions**
   ```bash
   adb shell pm dump com.focusblocker | grep permission
   ```

#### Solutions

**Solution 1: Grant Query Permission**
```bash
adb shell pm grant com.focusblocker android.permission.QUERY_ALL_PACKAGES
```

**Solution 2: Install More Apps**
- App list only shows non-system third-party apps
- Google Play Store, Settings are system apps (excluded)

**Solution 3: Filter Issue**
Check `android/app/src/main/kotlin/com/focusblocker/MainActivity.kt`:
```kotlin
// This line excludes system apps
if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0)
```

## Problem: Time Configuration Won't Save

### Symptom: Set times, but they revert on app restart

#### Diagnosis Steps
1. **Check Storage Permission**
   ```bash
   adb shell pm dump com.focusblocker | grep FILES
   ```

2. **Verify SharedPreferences**
   ```bash
   adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml
   ```

#### Solutions

**Solution 1: Check Storage Space**
```bash
adb shell df /data
```
Ensure at least 100MB free

**Solution 2: Verify Permissions**
```bash
adb shell pm grant com.focusblocker android.permission.WRITE_EXTERNAL_STORAGE
```

**Solution 3: Clear Cache**
```bash
adb shell pm clear com.focusblocker
```

## Problem: Strict Mode Not Working

### Symptom: Can close blocking screen even with Strict Mode enabled

#### Solutions

**Solution 1: Verify Stored Setting**
```bash
adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml | grep strict_mode
```

**Solution 2: Check BlockingActivity.kt**
Verify close button logic:
```kotlin
if (strictMode) {
    closeButton.isEnabled = false
    // ...
}
```

**Solution 3: Rebuild**
```bash
flutter clean
flutter build apk --debug
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

## Advanced Debugging

### Enable Verbose Logging
Add to MainActivity.kt:
```kotlin
override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    // Add logging to method channel handler
    Log.d("FocusBlocker_Main", "Method called: ${call.method}")
    Log.d("FocusBlocker_Main", "Arguments: ${call.arguments}")
}
```

### Real-time Log Monitoring
```bash
# Terminal 1: Connect to device and monitor accessibility service
adb logcat | grep "CustomAccessibilityService"

# Terminal 2: Monitor app blocking service
adb logcat | grep "AppBlockingService"

# Terminal 3: Monitor platform channel
adb logcat | grep "FocusBlocker_Main"
```

### Check Device Status
```bash
# All info
adb devices -l

# Android version
adb shell getprop ro.build.version.release

# Device model
adb shell getprop ro.product.model

# Manufacturer
adb shell getprop ro.product.manufacturer
```

## Device-Specific Issues

### Samsung (One UI)
- Usually blocks persistent services aggressively
- Solution: Add to "Sleeping apps" whitelist
- Settings → Apps → Special access → Sleeping apps

### Xiaomi (MIUI)
- Uses aggressive power management
- Solution: Disable "Get app notifications" in Battery Saver
- Settings → Battery and device care → Battery Saver

### Google Pixel
- Generally works without extra configuration
- May need battery optimization whitelist

### Huawei (EMUI)
- Very aggressive process management
- Solution: Add to Protected apps list
- Settings → Apps → Protected apps

## Performance Debugging

### Check Memory Usage
```bash
adb shell dumpsys meminfo com.focusblocker
```

### Check CPU Usage
```bash
adb shell top -n 1 | grep focusblocker
```

### Check Battery Impact
Connect to device and:
1. Settings → Battery → Battery usage → FocusBlocker
2. Should show minimal impact

## Getting Help

If issue persists:

1. **Collect Logs**
   ```bash
   adb logcat > focusblocker_logs.txt
   adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml > config.xml
   adb shell pm dump com.focusblocker > app_info.txt
   ```

2. **Include Device Info**
   - Android version
   - Device model
   - App version (Build number in About)

3. **Describe Reproduction Steps**
   - Exact steps to reproduce
   - When issue occurs
   - Apps involved

4. **Check Logs for Patterns**
   - Search for ERROR or Exception
   - Look for timestamps around issue time
