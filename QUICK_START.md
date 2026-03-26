# FocusBlocker - Quick Start Guide

## Installation & First Run (5 minutes)

### Prerequisites
- Android device with API 21+ 
- Flutter SDK installed
- Android Studio or VS Code with Flutter plugin

### Step-by-Step

#### 1. Clone/Open Project
```bash
cd FocusBlocker
flutter pub get
flutter clean
```

#### 2. Connect Device
```bash
# Check connected devices
flutter devices

# Enable USB debugging on your phone
# Device → Settings → Developer Options → USB Debugging → ON
```

#### 3. Run App
```bash
flutter run
```

#### 4. Initial Setup (First Time Only)
1. App starts showing main screen
2. Tap **Permissions** button
3. Tap **Enable** for Accessibility Service
4. Follow system prompt to Settings
5. Find "FocusBlocker" in Accessibility Services list
6. Toggle ON

#### 5. Test Blocking
1. Tap **Select Apps**
2. Search for an app you frequently use
3. Select it (checkbox appears)
4. Tap **Done**
5. Tap **Configure Time**
6. Set start time to NOW, end time to 10 minutes from now
7. Toggle **Strict Mode OFF** (for first test)
8. Tap **Start Blocking**
9. Immediately try opening the app you blocked
10. Blocking screen should appear

## Common First-Time Issues

### Issue: "Please enable Accessibility Service"
**Solution**: 
- Go to Settings → Accessibility → Services
- Scroll down to FocusBlocker
- Toggle it ON
- Grant all permissions when prompted

### Issue: App still opens (not blocked)
**Solution**:
- Check current time is between start and end time
- Verify app name shows in "Blocked Apps" list
- Make sure Accessibility Service is truly enabled
- Try rebooting device

### Issue: Cannot close blocking screen
**Solution**: 
- Turn OFF strict mode before testing
- Device must be restarted if stuck
- Or wait for timer to expire

## How to Use

### Basic Flow
1. Home Screen → Select Apps
2. Choose the apps you want to block
3. Home Screen → Configure Time
4. Set blocking window
5. Home Screen → Start Blocking
6. Blocking is active (green indicator)

### Advanced: Strict Mode
- Enable "Strict Mode" for unbreakable blocks
- Cannot close blocking screen until time expires
- Cannot disable blocking until time ends
- Use this for important focus sessions

### Stop Blocking Anytime
- Tap "Stop Blocking" button (only if not Strict Mode)
- Goes back to home screen

## Configuration Files

### Where Data is Stored
```
Device Storage → /data/data/com.focusblocker/shared_prefs/blocking_config.xml
```

Contains:
- Active blocked apps
- Start/end times  
- Strict mode setting
- Active status

## Keyboard Shortcuts (If Applicable)
- **N/A**: This app doesn't support keyboard shortcuts

## Tips for Best Results

✅ **Do**:
- Enable Battery Optimization whitelist
- Keep Accessibility Service enabled
- Test with one app first
- Set realistic time windows

❌ **Don't**:
- Force-stop the app during blocking
- Uninstall during active blocking
- Disable Accessibility Service while blocking is active
- Use on devices with aggressive RAM management

## Performance Impact
- Minimal CPU usage (< 1% when idle)
- Memory: ~20-30 MB
- Battery drain: < 1% per hour
- Network: None

## Backup & Reset

### Backup Settings
Settings are saved in SharedPreferences:
```bash
adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml > backup.xml
```

### Reset Everything
```bash
adb shell pm clear com.focusblocker
```

## Uninstall
```bash
# Via ADB
adb uninstall com.focusblocker

# Via Device
Settings → Apps → FocusBlocker → Uninstall
```

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for advanced issues
- Review [CODE_GUIDE.md](CODE_GUIDE.md) for technical details
