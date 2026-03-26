package com.focusblocker

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class CustomAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "FocusBlocker_A11y"
    }

    private var currentForegroundPackage = ""
    private var blockedPackages = setOf<String>()
    private var startTime = 0L
    private var endTime = 0L
    private var strictMode = false
    private var isBlockingActive = false

    override fun onServiceConnected() {
        Log.d(TAG, "Accessibility Service Connected")
        
        // Configure the accessibility service
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        setServiceInfo(info)
        
        // Load configuration
        loadBlockingConfig()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Get the package name of the current foreground app
        val packageName = event.packageName?.toString() ?: return
        
        if (packageName != currentForegroundPackage) {
            currentForegroundPackage = packageName
            Log.d(TAG, "Foreground app changed: $packageName")
            
            // Check if this app should be blocked
            checkAndBlockApp(packageName)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    private fun checkAndBlockApp(packageName: String) {
        // Reload configuration
        loadBlockingConfig()

        if (!isBlockingActive) return
        if (!blockedPackages.contains(packageName)) return
        
        // Check if current time is within blocking window
        val currentTime = System.currentTimeMillis()
        if (currentTime !in startTime..endTime) return

        Log.d(TAG, "Blocking app: $packageName")
        
        // Launch the blocking activity
        val intent = Intent(this, BlockingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            putExtra("blocked_package", packageName)
            putExtra("strict_mode", strictMode)
        }
        startActivity(intent)
    }

    private fun loadBlockingConfig() {
        val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        
        isBlockingActive = sharedPref.getBoolean("is_active", false)
        blockedPackages = sharedPref.getStringSet("blocked_packages", emptySet()) ?: emptySet()
        startTime = sharedPref.getLong("start_time", 0L)
        endTime = sharedPref.getLong("end_time", 0L)
        strictMode = sharedPref.getBoolean("strict_mode", false)
        
        Log.d(TAG, "Config loaded: active=$isBlockingActive, packages=$blockedPackages")
    }
}
