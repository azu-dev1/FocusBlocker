# FocusBlocker - Code Architecture Guide

## Overview

FocusBlocker uses a **Platform Channel** architecture to bridge Flutter (UI) and Kotlin (system integration).

```
┌─────────────────────────────────────────────────┐
│             Flutter Layer (Dart)                │
│  - UI Components (Screens)                      │
│  - Local Storage (SharedPreferences wrapper)   │
│  - User Configuration Management               │
└──────────────────┬──────────────────────────────┘
                   │
                   │ Method Channel
                   │ "com.focusblocker/blocking"
                   │
┌──────────────────▼──────────────────────────────┐
│            Kotlin Layer (Android)               │
│  - Platform Channel Handler                    │
│  - Accessibility Service (Monitoring)          │
│  - Foreground Service (Persistence)            │
│  - Blocking Activity (UI When Blocked)         │
└─────────────────────────────────────────────────┘
```

## Flutter Architecture

### File Structure
```
lib/
├── main.dart                              # App entry point, theme setup
├── services/
│   ├── blocking_service.dart              # Platform channel interface
│   └── storage_service.dart               # Persistent data with SharedPreferences
├── screens/
│   ├── home_screen.dart                   # Main dashboard
│   ├── app_selection_screen.dart          # Multi-select app picker
│   ├── scheduling_screen.dart             # Time configuration UI
│   └── permissions_screen.dart            # Permissions guidance
```

### 1. Main Entry Point (lib/main.dart)

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusBlocker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

**Responsibility**: Initialize and configure the Flutter app
**Key Points**:
- Sets up Material 3 theme
- Routes to HomeScreen as main entry
- Can be extended with navigation routing

### 2. Platform Channel Service (lib/services/blocking_service.dart)

```dart
class BlockingService {
  static const platform = MethodChannel('com.focusblocker/blocking');
}
```

**Methods**:

#### startBlocking()
```dart
static Future<bool> startBlocking({
  required List<String> packageNames,
  required DateTime startTime,
  required DateTime endTime,
  required bool strictMode,
}) async {
  final result = await platform.invokeMethod<bool>('startBlocking', {
    'packageNames': packageNames,
    'startTime': startTime.millisecondsSinceEpoch,
    'endTime': endTime.millisecondsSinceEpoch,
    'strictMode': strictMode,
  });
  return result ?? false;
}
```

**Flow**:
1. Called when user clicks "Start Blocking"
2. Sends data through MethodChannel to Kotlin
3. Kotlin receives and starts service
4. Returns success/failure

**Data passed**:
- `packageNames`: List of app package names to block
- `startTime/endTime`: Unix milliseconds timestamp (easier for time comparisons)
- `strictMode`: Boolean for strict mode

#### stopBlocking()
```dart
static Future<bool> stopBlocking() async {
  final result = await platform.invokeMethod<bool>('stopBlocking');
  return result ?? false;
}
```

**Flow**:
1. Called when user clicks "Stop Blocking"
2. Tells Kotlin to stop listening
3. Kotlin stops foreground service

#### isAccessibilityServiceEnabled()
```dart
static Future<bool> isAccessibilityServiceEnabled() async {
  try {
    final result = await platform.invokeMethod<bool>(
      'isAccessibilityServiceEnabled'
    );
    return result ?? false;
  } catch (e) {
    return false;
  }
}
```

**Purpose**: Check if user has enabled Accessibility Service
**Used**: Show warning on home screen if not enabled

#### getInstalledApps()
```dart
static Future<List<AppInfo>> getInstalledApps() async {
  try {
    final result = await platform.invokeMethod<List>('getInstalledApps');
    if (result == null) return [];
    
    return (result as List)
        .map((app) => AppInfo.fromMap(Map<String, dynamic>.from(app as Map)))
        .toList();
  } catch (e) {
    return [];
  }
}
```

**Purpose**: Get list of installed apps for selection
**Return**: List of AppInfo objects with app name, package name
**Note**: Only returns non-system apps (excluding itself)

### 3. Storage Service (lib/services/storage_service.dart)

Wrapper around SharedPreferences for type-safe data access.

```dart
class StorageService {
  static const String _blockedAppsKey = 'blocked_apps';
  static const String _blockStartTimeKey = 'block_start_time';
  static const String _blockEndTimeKey = 'block_end_time';
  // ... other keys
}
```

**Key Methods**:

```dart
// Save configuration
await StorageService.saveBlockedApps(apps);
await StorageService.saveBlockingWindow(startTime, endTime);
await StorageService.setStrictMode(true);

// Load configuration
List<String> apps = await StorageService.getBlockedApps();
(DateTime?, DateTime?) times = await StorageService.getBlockingWindow();
bool strict = await StorageService.getStrictMode();

// State management
await StorageService.setBlockingActive(true);
bool active = await StorageService.isBlockingActive();
```

**Purpose**: Serve as single source of truth for local data
**Persistence**: Survives app restarts, only cleared on uninstall/clear data

### 4. Home Screen (lib/screens/home_screen.dart)

Main dashboard with:
- Status indicator (blocking active/inactive)
- Blocked apps display with chips
- Time display
- Strict mode toggle
- Action buttons (Select Apps, Configure Time, Permissions)
- Start/Stop buttons

**State Management**:
```dart
class _HomeScreenState extends State<HomeScreen> {
  bool _isBlockingActive = false;
  List<String> _blockedApps = [];
  DateTime? _blockStartTime;
  DateTime? _blockEndTime;
  bool _strictMode = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    // Reload state from storage and native layer
  }
}
```

**Key Method: _startBlocking()**
```dart
Future<void> _startBlocking() async {
  // 1. Validate user input
  if (_blockedApps.isEmpty) return;
  if (_blockStartTime == null || _blockEndTime == null) return;
  if (!_accessibilityEnabled) return;

  // 2. Call native service
  final success = await BlockingService.startBlocking(
    packageNames: _blockedApps,
    startTime: _blockStartTime!,
    endTime: _blockEndTime!,
    strictMode: _strictMode,
  );

  // 3. Update state
  if (success) {
    await StorageService.setBlockingActive(true);
    setState(() => _isBlockingActive = true);
  }
}
```

### 5. App Selection Screen

Multi-select UI for choosing apps to block:

```dart
class _AppSelectionScreenState extends State<AppSelectionScreen> {
  late List<String> _selectedApps;
  late Future<List<AppInfo>> _appsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    _selectedApps = List.from(widget.selectedApps);  // Preserve previous selection
    _appsFuture = BlockingService.getInstalledApps();
  }
}
```

**Features**:
- Search/filter apps
- CheckboxListTile for each app
- Package name display as subtitle
- Done button to save selection
- Maintains selection state during navigation

### 6. Scheduling Screen

Time picker UI:

```dart
Future<void> _selectStartTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime: _startTime,
  );
  if (picked != null) {
    setState(() => _startTime = picked);
  }
}

void _saveSchedule() {
  final startDateTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _startTime.hour,
    _startTime.minute,
  );
  // Validate and save
}
```

**Features**:
- Date picker (today or future)
- Start time picker (any time)
- End time picker (must be after start)
- Validation (start < end)

### 7. Permissions Screen

Guides user through required permissions:

```dart
Future<void> _enableAccessibilityService() async {
  final result = await BlockingService.enableAccessibilityService();
  // Opens Settings → Accessibility automatically
}
```

## Kotlin Architecture

### File Structure
```
android/app/src/main/kotlin/com/focusblocker/
├── MainActivity.kt                    # Platform channel handler
├── CustomAccessibilityService.kt      # Foreground app monitor
├── AppBlockingService.kt              # Persistent service
└── BlockingActivity.kt                # Blocking screen UI
```

### 1. MainActivity.kt - Platform Channel Handler

**Purpose**: Bridge between Flutter and Kotlin native code

```kotlin
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.focusblocker/blocking"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBlocking" -> { /* ... */ }
                "stopBlocking" -> { /* ... */ }
                // ... other methods
            }
        }
    }
}
```

**Key Methods**:

#### startBlocking
```kotlin
private fun startBlocking(
    packageNames: List<String>,
    startTime: Long,
    endTime: Long,
    strictMode: Boolean
) {
    // 1. Save to SharedPreferences
    val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
    with(sharedPref.edit()) {
        putStringSet("blocked_packages", packageNames.toSet())
        putLong("start_time", startTime)
        putLong("end_time", endTime)
        putBoolean("strict_mode", strictMode)
        putBoolean("is_active", true)
        apply()
    }

    // 2. Start foreground service
    val serviceIntent = Intent(this, AppBlockingService::class.java)
    serviceIntent.action = AppBlockingService.ACTION_START_BLOCKING
    serviceIntent.putStringArrayListExtra("blocked_packages", ArrayList(packageNames))
    // ...
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        startForegroundService(serviceIntent)
    } else {
        startService(serviceIntent)
    }
}
```

**Data Flow**:
1. Receives blocking configuration from Flutter
2. Validates package names (not empty)
3. Saves to SharedPreferences (persistent across app kills)
4. Starts AppBlockingService with configuration

#### getInstalledApps
```kotlin
private fun getInstalledApps(): List<Map<String, String>> {
    val apps = mutableListOf<Map<String, String>>()
    val installedPackages = packageManager.getInstalledApplications(
        PackageManager.GET_META_DATA
    )

    for (appInfo in installedPackages) {
        // Skip system apps
        if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
            val appName = appInfo.loadLabel(packageManager).toString()
            val packageName = appInfo.packageName
            
            if (packageName != this.packageName) {  // Skip self
                apps.add(mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                ))
            }
        }
    }
    
    return apps.sortedBy { it["appName"] }  // A-Z sort
}
```

**Key Points**:
- Only non-system apps (excludes Settings, etc.)
- Excludes FocusBlocker itself
- Sorted alphabetically for UI
- Includes package name (for blocking)

#### isAccessibilityServiceEnabled
```kotlin
private fun isAccessibilityServiceEnabled(): Boolean {
    val service = "${packageName}/.CustomAccessibilityService"
    return try {
        val enabled = android.provider.Settings.Secure.getString(
            context.contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        enabled?.contains(service) ?: false
    } catch (e: Exception) {
        false
    }
}
```

**Logic**: Queries Android Settings to check if our accessibility service is in enabled list

### 2. CustomAccessibilityService.kt - Foreground App Monitor

**Purpose**: Continuously monitor what app is currently open and trigger blocking

```kotlin
class CustomAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val packageName = event.packageName?.toString() ?: return
        
        if (packageName != currentForegroundPackage) {
            currentForegroundPackage = packageName
            checkAndBlockApp(packageName)  // New app came to foreground
        }
    }
}
```

**Event Flow**:
1. Android fires AccessibilityEvent when:
   - App comes to foreground
   - Window state changes
   - User interacts with UI

2. Service checks if package changed
3. If changed, calls checkAndBlockApp()

#### checkAndBlockApp
```kotlin
private fun checkAndBlockApp(packageName: String) {
    loadBlockingConfig()  // Re-read from SharedPreferences
    
    if (!isBlockingActive) return
    if (!blockedPackages.contains(packageName)) return
    
    // Check time window
    val currentTime = System.currentTimeMillis()
    if (currentTime !in startTime..endTime) return
    
    // All checks passed - launch blocking activity
    val intent = Intent(this, BlockingActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_NO_HISTORY
        putExtra("blocked_package", packageName)
        putExtra("strict_mode", strictMode)
    }
    startActivity(intent)
}
```

**Decision Logic**:
1. Is blocking currently active? ❌ → Exit
2. Is app in blocked list? ❌ → Exit
3. Is current time within window? ❌ → Exit
4. ✅ All pass → Launch BlockingActivity

**Configuration Reload**: Every event reloads from SharedPreferences to get latest config

### 3. AppBlockingService.kt - Persistent Service

**Purpose**: Stay alive in background as foreground service to ensure reliability

```kotlin
class AppBlockingService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_START_BLOCKING -> {
                startBlocking(intent)
                Service.START_STICKY  // Restart if killed
            }
            ACTION_STOP_BLOCKING -> {
                stopBlocking()
                Service.START_NOT_STICKY
            }
            else -> {
                resumeBlocking()  // Resume from crash
                Service.START_STICKY
            }
        }
    }
}
```

**Key Features**:

1. **Foreground Service**
   ```kotlin
   startForeground(NOTIFICATION_ID, buildNotification())
   ```
   - Creates persistent notification
   - Prevents system from killing service
   - Shows blocking status to user

2. **Monitoring Thread**
   ```kotlin
   Thread {
       while (isRunning) {
           val currentTime = System.currentTimeMillis()
           if (currentTime >= endTime) {
               stopBlocking()
               return@Thread
           }
           Thread.sleep(5000)  // Check every 5 seconds
       }
   }.start()
   ```
   - Runs every 5 seconds
   - Checks if blocking window has expired
   - Auto-stops when time is up

3. **Crash Recovery**
   ```kotlin
   private fun resumeBlocking() {
       val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
       val isActive = sharedPref.getBoolean("is_active", false)
       if (isActive) {
           // Restore state from SharedPreferences
           blockedPackages = config...
           startForeground(NOTIFICATION_ID, buildNotification())
       }
   }
   ```
   - If service crashes/restarts, reads config from SharedPreferences
   - Resumes blocking transparently

### 4. BlockingActivity.kt - Blocking Screen

**Purpose**: Full-screen activity shown when blocked app is opened

```kotlin
class BlockingActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Window configuration
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        // Hide navigation/status bars
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        setContentView(R.layout.activity_blocking)
        setupUI()
    }
}
```

**Window Flags**:
- `FLAG_KEEP_SCREEN_ON`: Screen stays on
- `FLAG_SHOW_WHEN_LOCKED`: Shows on lock screen
- `FLAG_TURN_SCREEN_ON`: Wakes display
- `IMMERSIVE_STICKY`: Hides system UI and prevents gestures

#### Anti-Navigation Logic

```kotlin
override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    if (keyCode == KeyEvent.KEYCODE_BACK) {
        return true  // Consume back button
    }
    if (keyCode == KeyEvent.KEYCODE_HOME && strictMode) {
        return true  // Consume home button in strict mode
    }
    return super.onKeyDown(keyCode, event)
}

override fun onPause() {
    super.onPause()
    if (!canClose) {
        // Immediately return to this activity
        val intent = Intent(this, BlockingActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
}
```

**Prevents**:
- Back button from closing
- Task switcher from switching
- Home button (in strict mode)

#### Strict Mode Timer

```kotlin
private fun setupUI() {
    if (strictMode) {
        closeButton.isEnabled = false
        closeButton.text = "Cannot close (Strict Mode)"
    }
    
    // Countdown thread
    Thread {
        while (!canClose && strictMode) {
            Thread.sleep(1000)
            val currentTime = System.currentTimeMillis()
            runOnUiThread {
                if (currentTime >= endTime) {
                    canClose = true
                    closeButton.isEnabled = true
                    closeButton.text = "Time's up! Close"
                    finish()
                } else {
                    updateRemainingTime(timeTextView)
                }
            }
        }
    }.start()
}
```

**Behavior**:
- Displays countdown timer
- Auto-closes when time expires
- Button never becomes clickable until timer ends

## Data Flow Diagram

```
User Action              Flutter Layer           Platform Channel         Kotlin Layer
─────────────────────────────────────────────────────────────────────────────────────

[Tap Start Blocking]
                    ├─ Validate data
                    ├─ Save to StorageService
                    └─ Call BlockingService.startBlocking()
                                              │
                                              ├→ startBlocking()
                                              │   └─ Save to SharedPreferences
                                              │   └─ Start AppBlockingService
                                              │
User opens app                                └─ AppBlockingService runs
                                                 ├─ AccessibilityService monitors
                                                 ├─ App in foreground
                                                 ├─ checkAndBlockApp() called
                                                 ├─ Time check passes
                                                 ├─ Package in blocked list
                                                 └─ Launch BlockingActivity

[BlockingActivity Shown]
User sees:
├─ Red "App Blocked" message
├─ App name
├─ Remaining time (Strict Mode)
└─ Close button (disabled if Strict Mode)

[Time expires or user closes]
                    BlockingActivity.finish()
                    └─ onPause() check passes
                        └─ Activity destroyed

Blocking stopped
                    ├─ StorageService.setBlockingActive(false)
                    ├─ Call BlockingService.stopBlocking()
                    └─ AppBlockingService.stopBlocking()
                                              │
                                              └─ Stop foreground service
                                              └─ Clear notification
```

## SharedPreferences Schema

Located at: `/data/data/com.focusblocker/shared_prefs/blocking_config.xml`

```xml
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<map>
    <!-- Blocked apps (Set) -->
    <set name="blocked_packages">
        <string>com.example.app1</string>
        <string>com.example.app2</string>
    </set>
    
    <!-- Time window (Long, Unix milliseconds) -->
    <long name="start_time" value="1234567890000"/>
    <long name="end_time" value="1234567899000"/>
    
    <!-- Settings -->
    <boolean name="strict_mode" value="true"/>
    <boolean name="is_active" value="true"/>
</map>
```

## Platform Channel Protocol

### Method: startBlocking

**From Flutter**:
```dart
final result = await platform.invokeMethod<bool>('startBlocking', {
  'packageNames': ['com.example.app'],
  'startTime': 1609459200000,  // Unix ms
  'endTime': 1609462800000,    // Unix ms
  'strictMode': true,
});
```

**Kotlin Receives**:
```kotlin
val packageNames = call.argument<List<String>>("packageNames")
val startTime = call.argument<Long>("startTime")
val endTime = call.argument<Long>("endTime")
val strictMode = call.argument<Boolean>("strictMode")
```

**Return**: `true` if successful, `false` otherwise

### Method: getInstalledApps

**From Flutter**:
```dart
final result = await platform.invokeMethod<List>('getInstalledApps');
```

**Kotlin Returns**:
```kotlin
listOf(
    mapOf(
        "appName" to "Facebook",
        "packageName" to "com.facebook.katana",
    ),
    // ...
)
```

**Parsed to**:
```dart
class AppInfo {
  final String packageName;
  final String appName;
}
```

## Extension Points

### Add New Blocking Mode
1. Add field to StorageService
2. Add UI in SchedulingScreen
3. Pass via startBlocking() method
4. Implement logic in CustomAccessibilityService

### Add Notifications
1. Extend BlockingActivity to send notification
2. Create NotificationCompat.Builder
3. Post via NotificationManager

### Add Statistics
1. Track blocked events in SharedPreferences
2. Display in new StatisticsScreen
3. Add analytics database if needed

## Common Modifications

### Change Check Interval
AppBlockingService.kt:
```kotlin
Thread.sleep(5000)  // Change to desired milliseconds
```

### Change System UI Visibility
BlockingActivity.kt:
```kotlin
window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE  // Show UI
```

### Add Sound/Vibration
BlockingActivity.kt:
```kotlin
val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
vibrator.vibrate(500)  // 500ms vibration
```

### Customize Notification
AppBlockingService.kt:
```kotlin
private fun buildNotification(): Notification {
    return NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Custom Title")
        .setStyle(NotificationCompat.BigTextStyle().bigText("Details"))
        // ...
        .build()
}
```
