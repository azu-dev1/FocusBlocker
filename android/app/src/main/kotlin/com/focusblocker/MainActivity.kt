package com.focusblocker

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.focusblocker/blocking"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val context: Context = this
        val packageManager: PackageManager = this.packageManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBlocking" -> {
                    val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: 0L
                    val strictMode = call.argument<Boolean>("strictMode") ?: false

                    startBlocking(packageNames, startTime, endTime, strictMode, context, packageManager)
                    result(true)
                }
                "stopBlocking" -> {
                    stopBlocking(context)
                    result(true)
                }
                "getBlockingStatus" -> {
                    val status = getBlockingStatus(context)
                    result(status)
                }
                "enableAccessibilityService" -> {
                    openAccessibilitySettings(context)
                    result(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    val enabled = isAccessibilityServiceEnabled(context)
                    result(enabled)
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps(context)
                    result(apps)
                }
                else -> result(null)
            }
        }
    }

    private fun startBlocking(
        packageNames: List<String>,
        startTime: Long,
        endTime: Long,
        strictMode: Boolean,
        context: Context,
        packageManager: PackageManager
    ) {
        // Save configuration to SharedPreferences
        val sharedPref = context.getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        with(sharedPref.edit()) {
            putStringSet("blocked_packages", packageNames.toSet())
            putLong("start_time", startTime)
            putLong("end_time", endTime)
            putBoolean("strict_mode", strictMode)
            putBoolean("is_active", true)
            apply()
        }

        // Start the foreground service
        val serviceIntent = Intent(context, AppBlockingService::class.java)
        serviceIntent.action = AppBlockingService.ACTION_START_BLOCKING
        serviceIntent.putStringArrayListExtra("blocked_packages", ArrayList(packageNames))
        serviceIntent.putExtra("start_time", startTime)
        serviceIntent.putExtra("end_time", endTime)
        serviceIntent.putExtra("strict_mode", strictMode)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun stopBlocking(context: Context) {
        val sharedPref = context.getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        with(sharedPref.edit()) {
            putBoolean("is_active", false)
            apply()
        }

        val serviceIntent = Intent(context, AppBlockingService::class.java)
        serviceIntent.action = AppBlockingService.ACTION_STOP_BLOCKING
        context.stopService(serviceIntent)
    }

    private fun getBlockingStatus(context: Context): Map<String, Any> {
        val sharedPref = context.getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        return mapOf(
            "isActive" to (sharedPref.getBoolean("is_active", false)),
            "blockedPackages" to (sharedPref.getStringSet("blocked_packages", emptySet()) ?: emptySet()),
            "startTime" to (sharedPref.getLong("start_time", 0L)),
            "endTime" to (sharedPref.getLong("end_time", 0L)),
            "strictMode" to (sharedPref.getBoolean("strict_mode", false))
        )
    }

    private fun openAccessibilitySettings(context: Context) {
        val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
        context.startActivity(intent)
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val service = "${context.packageName}/.CustomAccessibilityService"
        var result = false
        try {
            val enabled = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            result = enabled?.contains(service) ?: false
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    private fun getInstalledApps(context: Context): List<Map<String, String>> {
        val apps = mutableListOf<Map<String, String>>()
        val packageManager: PackageManager = context.packageManager
        val installedPackages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in installedPackages) {
            // Skip system apps
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                val appName = appInfo.loadLabel(packageManager).toString()
                val packageName = appInfo.packageName
                
                // Skip the app itself
                if (packageName != context.packageName) {
                    apps.add(
                        mapOf(
                            "appName" to appName,
                            "packageName" to packageName,
                            "iconPath" to ""
                        )
                    )
                }
            }
        }

        return apps.sortedBy { it["appName"] ?: "" }
    }
}
