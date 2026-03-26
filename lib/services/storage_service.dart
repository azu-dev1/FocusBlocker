import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _blockedAppsKey = 'blocked_apps';
  static const String _blockStartTimeKey = 'block_start_time';
  static const String _blockEndTimeKey = 'block_end_time';
  static const String _strictModeKey = 'strict_mode';
  static const String _blockingActiveKey = 'blocking_active';

  /// Save blocked apps list
  static Future<void> saveBlockedApps(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedAppsKey, packageNames);
  }

  /// Get blocked apps list
  static Future<List<String>> getBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_blockedAppsKey) ?? [];
  }

  /// Save blocking time window
  static Future<void> saveBlockingWindow(DateTime startTime, DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_blockStartTimeKey, startTime.millisecondsSinceEpoch);
    await prefs.setInt(_blockEndTimeKey, endTime.millisecondsSinceEpoch);
  }

  /// Get blocking time window
  static Future<(DateTime?, DateTime?)> getBlockingWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_blockStartTimeKey);
    final endMs = prefs.getInt(_blockEndTimeKey);
    
    if (startMs == null || endMs == null) {
      return (null, null);
    }
    
    return (
      DateTime.fromMillisecondsSinceEpoch(startMs),
      DateTime.fromMillisecondsSinceEpoch(endMs),
    );
  }

  /// Save strict mode preference
  static Future<void> setStrictMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_strictModeKey, enabled);
  }

  /// Get strict mode preference
  static Future<bool> getStrictMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_strictModeKey) ?? false;
  }

  /// Save blocking active state
  static Future<void> setBlockingActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockingActiveKey, active);
  }

  /// Get blocking active state
  static Future<bool> isBlockingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_blockingActiveKey) ?? false;
  }

  /// Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
