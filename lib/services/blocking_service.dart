import 'package:flutter/services.dart';

class BlockingService {
  static const platform = MethodChannel('com.focusblocker/blocking');

  /// Start blocking apps
  static Future<bool> startBlocking({
    required List<String> packageNames,
    required DateTime startTime,
    required DateTime endTime,
    required bool strictMode,
  }) async {
    try {
      final result = await platform.invokeMethod<bool>('startBlocking', {
        'packageNames': packageNames,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'strictMode': strictMode,
      });
      return result ?? false;
    } catch (e) {
      print('Error starting blocking: $e');
      return false;
    }
  }

  /// Stop blocking apps
  static Future<bool> stopBlocking() async {
    try {
      final result = await platform.invokeMethod<bool>('stopBlocking');
      return result ?? false;
    } catch (e) {
      print('Error stopping blocking: $e');
      return false;
    }
  }

  /// Get blocking status
  static Future<Map<dynamic, dynamic>> getBlockingStatus() async {
    try {
      final result = await platform.invokeMethod<Map>('getBlockingStatus');
      return result ?? {};
    } catch (e) {
      print('Error getting blocking status: $e');
      return {};
    }
  }

  /// Enable accessibility service
  static Future<bool> enableAccessibilityService() async {
    try {
      final result = await platform.invokeMethod<bool>('enableAccessibilityService');
      return result ?? false;
    } catch (e) {
      print('Error enabling accessibility service: $e');
      return false;
    }
  }

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await platform.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility service: $e');
      return false;
    }
  }

  /// Get list of installed apps
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await platform.invokeMethod<List>('getInstalledApps');
      if (result == null) return [];
      
      return (result as List)
          .map((app) => AppInfo.fromMap(Map<String, dynamic>.from(app as Map)))
          .toList();
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }
}

class AppInfo {
  final String packageName;
  final String appName;
  final String? iconPath;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconPath,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      iconPath: map['iconPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
    };
  }
}
