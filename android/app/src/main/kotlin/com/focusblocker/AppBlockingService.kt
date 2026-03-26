package com.focusblocker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AppBlockingService : Service() {

    companion object {
        const val ACTION_START_BLOCKING = "com.focusblocker.START_BLOCKING"
        const val ACTION_STOP_BLOCKING = "com.focusblocker.STOP_BLOCKING"
        private const val TAG = "FocusBlocker_Service"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "app_blocking_channel"
    }

    private var isRunning = false
    private lateinit var notificationManager: NotificationManager
    private var blockedPackages = setOf<String>()
    private var startTime = 0L
    private var endTime = 0L
    private var strictMode = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service Created")
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service Started with action: ${intent?.action}")

        return when (intent?.action) {
            ACTION_START_BLOCKING -> {
                startBlocking(intent)
                Service.START_STICKY
            }
            ACTION_STOP_BLOCKING -> {
                stopBlocking()
                Service.START_NOT_STICKY
            }
            else -> {
                // Resume from crash or system restart
                resumeBlocking()
                Service.START_STICKY
            }
        }
    }

    private fun startBlocking(intent: Intent) {
        val packages = intent.getStringArrayListExtra("blocked_packages") ?: emptyList()
        val start = intent.getLongExtra("start_time", 0L)
        val end = intent.getLongExtra("end_time", 0L)
        val strict = intent.getBooleanExtra("strict_mode", false)

        blockedPackages = packages.toSet()
        startTime = start
        endTime = end
        strictMode = strict
        isRunning = true

        // Save configuration
        val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        with(sharedPref.edit()) {
            putStringSet("blocked_packages", blockedPackages)
            putLong("start_time", startTime)
            putLong("end_time", endTime)
            putBoolean("strict_mode", strictMode)
            putBoolean("is_active", true)
            apply()
        }

        // Start as foreground service
        startForeground(NOTIFICATION_ID, buildNotification())

        // Start monitoring thread
        startMonitoring()
    }

    private fun stopBlocking() {
        isRunning = false

        val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        with(sharedPref.edit()) {
            putBoolean("is_active", false)
            apply()
        }

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun resumeBlocking() {
        val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        val isActive = sharedPref.getBoolean("is_active", false)

        if (isActive) {
            blockedPackages = sharedPref.getStringSet("blocked_packages", emptySet()) ?: emptySet()
            startTime = sharedPref.getLong("start_time", 0L)
            endTime = sharedPref.getLong("end_time", 0L)
            strictMode = sharedPref.getBoolean("strict_mode", false)
            isRunning = true

            startForeground(NOTIFICATION_ID, buildNotification())
            startMonitoring()
        }
    }

    private fun startMonitoring() {
        Thread {
            while (isRunning) {
                val currentTime = System.currentTimeMillis()

                // Check if blocking period has ended
                if (currentTime >= endTime) {
                    Log.d(TAG, "Blocking period ended")
                    stopBlocking()
                    return@Thread
                }

                // Check accessibility service is still running
                if (!isAccessibilityServiceEnabled()) {
                    Log.w(TAG, "Accessibility service is not enabled, restarting...")
                    // The service should auto-restart, but we log a warning
                }

                // Update notification with remaining time
                updateNotification()

                Thread.sleep(5000) // Check every 5 seconds
            }
        }.start()
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val context = this
        val service = "${packageName}/.CustomAccessibilityService"
        return try {
            val enabled = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            enabled?.contains(service) ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service", e)
            false
        }
    }

    private fun buildNotification(): Notification {
        val remainingMs = (endTime - System.currentTimeMillis()).coerceAtLeast(0L)
        val seconds = (remainingMs / 1000) % 60
        val minutes = (remainingMs / (1000 * 60)) % 60
        val hours = (remainingMs / (1000 * 60 * 60)) % 24

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("FocusBlocker")
            .setContentText("Blocking ${blockedPackages.size} app(s) - ${String.format("%02d:%02d:%02d", hours, minutes, seconds)} remaining")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for app blocking status"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service Destroyed")
        isRunning = false
    }
}
