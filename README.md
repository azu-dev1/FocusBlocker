# FocusBlocker - Complete Guide

FocusBlocker is a Flutter-based Android application that allows users to block selected apps for a user-defined time period using real native Android blocking mechanisms.

## Features

✅ **Real App Blocking** - Uses Android Accessibility Service to detect and block apps
✅ **Multi-App Selection** - Block multiple apps simultaneously
✅ **Time-Based Blocking** - Set custom start and end times
✅ **Strict Mode** - Optional mode where blocking cannot be disabled until timer ends
✅ **Foreground Service** - Persistent service ensures reliability
✅ **Full-Screen Blocking** - Prevents app access completely
✅ **No Mock Data** - Real, production-ready implementation

## Project Structure

```
FocusBlocker/
├── lib/                                 # Flutter code
│   ├── main.dart                       # App entry point
│   ├── services/
│   │   ├── blocking_service.dart       # Platform Channel interface
│   │   └── storage_service.dart        # SharedPreferences wrapper
│   └── screens/
│       ├── home_screen.dart            # Main UI screen
│       ├── app_selection_screen.dart   # App selection UI
│       ├── scheduling_screen.dart      # Time configuration UI
│       └── permissions_screen.dart     # Permission management UI
├── android/
│   └── app/
│       ├── src/main/
│       │   ├── kotlin/com/focusblocker/
│       │   │   ├── MainActivity.kt                    # Platform Channel handler
│       │   │   ├── CustomAccessibilityService.kt     # Foreground app monitor
│       │   │   ├── BlockingActivity.kt               # Blocking screen
│       │   │   └── AppBlockingService.kt             # Foreground service
│       │   ├── res/
│       │   │   ├── layout/activity_blocking.xml      # Blocking screen layout
│       │   │   ├── values/strings.xml                # String resources
│       │   │   └── xml/accessibility_service.xml     # A11y config
│       │   └── AndroidManifest.xml                   # Manifest with permissions
│       └── build.gradle                              # App build configuration
└── pubspec.yaml                        # Flutter dependencies
```

## Prerequisites

- **Flutter SDK**: 3.0.0 or higher
- **Android SDK**: API 21-34
- **Kotlin**: 1.8.0+
- **Android Studio** or **VS Code** with Flutter extension
- **Real Android Device** (API 21+) for testing

## Setup Instructions

### Step 1: Initialize Flutter Project

```bash
# Navigate to project directory
cd FocusBlocker

# Get Flutter dependencies
flutter pub get

# Configure Flutter
flutter clean
```

### Step 2: Install Dependencies

Ensure all required packages are available:

```bash
flutter pub get
```

Key packages:
- `shared_preferences` - Local data storage
- `permission_handler` - Permission management
- `device_apps` - Get installed apps list (optional)

### Step 3: Build and Run Debug APK

```bash
# Run on connected device
flutter run

# Or build APK
flutter build apk --debug

# Transfer APK to device
adb install build/app/outputs/apk/debug/app-debug.apk
```

### Step 4: Enable Required Permissions

After installing the app, manually enable:

1. **Accessibility Service** (MANDATORY):
   - Settings → Accessibility → Services
   - Find "FocusBlocker"
   - Enable it
   - Grant all requested permissions

2. **Battery Optimization** (Recommended):
   - Settings → Apps → FocusBlocker
   - Battery → Battery Optimization → Don't optimize
   - (Ensures service isn't killed by system)

3. **Usage Access** (Optional but Recommended):
   - Settings → Apps → Special App Access → Usage Access
   - Enable FocusBlocker

### Step 5: Test the Application

1. **Install the App**: Tap "Start" in the FocusBlocker main screen
2. **Select Apps**: Navigate to "Select Apps" and choose apps to block
3. **Configure Time**: Set start and end times for blocking
4. **Enable Accessibility**: Go to "Permissions" tab and enable accessibility service
5. **Start Blocking**: Click "Start Blocking"
6. **Verify**: Try opening a blocked app - the blocking screen should appear

## How It Works

### Architecture Overview

```
┌─────────────────────────────────────────┐
│        Flutter UI Layer                  │
│  (App Selection, Scheduling, Status)    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      Platform Channel (MethodChannel)    │
│  Communication Bridge (Dart ↔ Kotlin)   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      MainActivity (Platform Handler)     │
│  - Receives blocking config              │
│  - Manages services                      │
│  - Handles permissions                   │
└─────────────────────────────────────────┘
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
┌──────────────────┐  ┌──────────────────────────┐
│ AccessibilityService   │      AppBlockingService    │
│   - Monitors         │  - Persistent monitoring  │
│     foreground app   │  - Time checking          │
│   - Detects when    │  - Triggers blocking      │
│     blocked app      │  - Keeps app alive        │
│     comes to front   │                          │
└──────────────────┘  └──────────────────────────┘
        ↓
┌─────────────────────────────────────────┐
│       BlockingActivity                   │
│  - Full-screen blocking UI               │
│  - Prevents navigation                   │
│  - Shows remaining time (Strict Mode)    │
│  - Cannot be dismissed (if Strict Mode)  │
└─────────────────────────────────────────┘
```

### Data Flow

1. **User Configuration** (Flutter side):
   - Select apps from installed apps list
   - Set blocking time window (start/end times)
   - Toggle strict mode
   - Save to SharedPreferences

2. **Start Blocking** (Flutter → Kotlin):
   - Flutter calls `BlockingService.startBlocking()`
   - Sends to Kotlin via Platform Channel
   - MainActivity receives and saves config to SharedPreferences
   - Starts AppBlockingService (Foreground Service)
   - AppBlockingService starts foreground notification

3. **Monitoring** (Kotlin side):
   - AccessibilityService monitors foreground app changes
   - When foreground app changes:
     - Loads config from SharedPreferences
     - Checks if current time is within blocking window
     - Checks if app is in blocked list
     - If yes → Launches BlockingActivity
   
4. **Blocking** (BlockingActivity):
   - Displays full-screen blocking UI
   - Prevents back/home button navigation
   - Shows remaining time (if Strict Mode)
   - In Strict Mode: Cannot close until timer expires
   - In Normal Mode: User can swipe away or click close

## Code Breakdown

### 1. Platform Channel (MainActivity.kt)

```kotlin
// Method Channel name - must match Flutter
private val CHANNEL = "com.focusblocker/blocking"

// Handles Flutter calls:
// - startBlocking: Start app blocking with config
// - stopBlocking: Stop app blocking
// - isAccessibilityServiceEnabled: Check if enabled
// - getInstalledApps: Get list of all non-system apps
// - getBlockingStatus: Get current blocking status
```

**Key Methods**:
- `startBlocking()` - Receives package names, time window, and saves to SharedPreferences
- `stopBlocking()` - Stops the foreground service and blocking
- `getInstalledApps()` - Returns list of non-system apps excluding self

### 2. Accessibility Service (CustomAccessibilityService.kt)

```kotlin
// Fired when accessibility event occurs
override fun onAccessibilityEvent(event: AccessibilityEvent?)

// Detects when foreground app changes (event.packageName)
// Loads blocking configuration
// Checks if app should be blocked
// Launches BlockingActivity if blocked
```

**Key Responsibilities**:
- Monitor all AccessibilityEvents
- Detect foreground app changes
- Load blocking configuration from SharedPreferences
- Check time window validity
- Launch BlockingActivity for blocked apps

### 3. Foreground Service (AppBlockingService.kt)

```kotlin
// Runs in foreground (visible notification)
// Ensures app isn't killed by system
// Creates persistent notification showing blocking status
// Periodically checks if blocking period has ended
```

**Key Responsibilities**:
- Maintain persistent foreground notification
- Resume blocking if system restarts service
- Monitor time window and auto-stop when time expires
- Check accessibility service health

### 4. Blocking Activity (BlockingActivity.kt)

```kotlin
// Full-screen activity displayed when blocked
// Flags:
// - FLAG_KEEP_SCREEN_ON: Keep screen on
// - FLAG_SHOW_WHEN_LOCKED: Show on lock screen
// - FLAG_IMMERSIVE_STICKY: Hide system UI

// Prevents:
// - Back button navigation
// - Home button (in Strict Mode)
// - Gesture navigation

// In Strict Mode:
// - Close button disabled
// - Shows countdown timer
// - Auto-closes when time expires
```

## Permission Explanations

| Permission | Purpose | Type |
|-----------|---------|------|
| `BIND_ACCESSIBILITY_SERVICE` | Enable accessibility service | System |
| `PACKAGE_USAGE_STATS` | Monitor app usage (optional) | Runtime |
| `GET_TASKS` | Get current foreground app | System |
| `QUERY_ALL_PACKAGES` | List all installed apps | Runtime |
| `SYSTEM_ALERT_WINDOW` | Show overlays | Runtime |
| `FOREGROUND_SERVICE` | Run persistent service | Runtime |
| `POST_NOTIFICATIONS` | Show notifications | Runtime |

## Troubleshooting

### Blocking Not Working

**Problem**: Apps open normally, blocking doesn't trigger

**Solutions**:
1. Check if Accessibility Service is enabled
   - Settings → Accessibility → Services → FocusBlocker
2. Verify time window is correct (current time must be between start and end)
3. Check SharedPreferences for saved config:
   ```bash
   adb shell run-as com.focusblocker cat /data/data/com.focusblocker/shared_prefs/blocking_config.xml
   ```
4. Check Logcat for errors:
   ```bash
   adb logcat | grep FocusBlocker
   ```

### Service Gets Killed

**Problem**: Blocking stops working after some time

**Solutions**:
1. Add app to Battery Optimization whitelist
2. Enable "Do not optimize" in Battery settings
3. Disable aggressive RAM/battery management:
   - Some ROMs (MIUI, OneUI) have aggressive process killing
   - Add to whitelist in manufacturer's optimization app

### Accessibility Service Not Starting

**Problem**: User enables in settings but service doesn't stay enabled

**Solutions**:
1. Some Android versions auto-disable unused services after 24 hours
2. Ensure app has all required permissions:
   ```bash
   adb shell pm dump com.focusblocker | grep permissions
   ```
3. Check for permission logs:
   ```bash
   adb logcat | grep "CustomAccessibilityService"
   ```

## Building Release APK

```bash
# Create keystore (if not exists)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# Build release APK
flutter build apk --release --keystore=~/key.jks --keystore-password=<password> --key-password=<password> --key-alias=key

# Output location:
# build/app/outputs/apk/release/app-release.apk
```

## Advanced Configuration

### Custom Blocking Screen

Edit `android/app/src/main/res/layout/activity_blocking.xml` to customize:
- Colors
- Messages
- Buttons
- Layout

### Modify Blocking Behavior

Edit `BlockingActivity.kt`:
- `onKeyDown()` - Control button behavior
- `onPause()` - Control when activity restarts
- `setupUI()` - Customize UI elements

### Change Accessibility Events

Edit `CustomAccessibilityService.kt`:
```kotlin
// Monitor different events by modifying:
val info = AccessibilityServiceInfo().apply {
    eventTypes = AccessibilityEvent.TYPES_ALL_MASK  // Change this
}
```

## Security Considerations

1. **Device Admin**: This app does NOT use Device Admin APIs (intentional)
2. **Accessibility Service**: Users can disable at any time
3. **SharedPreferences**: Non-encrypted (suitable for non-sensitive data)
4. **Persistence**: No guarantee of blocking if:
   - User force-stops app
   - Accessibility Service is disabled
   - Device is factory reset
   - Third-party optimization app kills service

## Performance Optimization

- Accessibility Service only processes events when UI visible
- SharedPreferences cached in memory
- Foreground Service uses low-priority notification channel
- No unnecessary network/disk I/O

## Testing Checklist

- [ ] Can select multiple apps
- [ ] Can set blocking time correctly
- [ ] Accessibility service enables successfully
- [ ] App blocks when opened during blocking window
- [ ] Blocking screen appears full-screen
- [ ] Cannot navigate away from blocking screen
- [ ] Blocking stops when time window ends
- [ ] Strict mode prevents closing
- [ ] Service survives lock screen
- [ ] Service resumes after device restart
- [ ] Battery optimization doesn't kill service
- [ ] Multiple instances of blocking don't crash

## Known Issues and Limitations

1. **System Apps**: Cannot block system apps (by design)
2. **Recent Apps**: Blocking may briefly show app name in recent apps menu
3. **Fastboot/Recovery**: Cannot block access to recovery or fastboot
4. **User Bypass**: Advanced users can disable from Settings
5. **API 24-25**: May have reduced blocking reliability on older Android versions
6. **Custom ROMs**: Some ROMs have aggressive process management

## Future Enhancements

- [ ] Whitelist mode (block all except selected apps)
- [ ] Schedule recurring blocks (e.g., daily 9-5)
- [ ] Statistics/usage tracking
- [ ] PIN protection for settings
- [ ] Notifications when blocked apps attempted
- [ ] Cloud sync for settings
- [ ] Multiple blocking sessions

## License

This project is provided as-is for educational and personal use.

## Support

For issues or questions, check:
1. Logcat output: `adb logcat | grep FocusBlocker`
2. Accessibility Service status
3. Android version compatibility
4. Battery optimization settings
