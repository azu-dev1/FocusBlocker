package com.focusblocker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.text.SimpleDateFormat
import java.util.*

class BlockingActivity : AppCompatActivity() {

    private var blockedPackage = ""
    private var strictMode = false
    private var endTime = 0L
    private var canClose = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set window attributes to keep it on top
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Set full screen and hide system UI
        val flags = (
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
            android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
        
        window.decorView.systemUiVisibility = flags

        setContentView(R.layout.activity_blocking)

        // Get data from intent
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        strictMode = intent.getBooleanExtra("strict_mode", false)

        // Load end time from SharedPreferences
        val sharedPref = getSharedPreferences("blocking_config", Context.MODE_PRIVATE)
        endTime = sharedPref.getLong("end_time", 0L)

        // Setup UI
        setupUI()

        // Check if we need to close this activity
        checkTimeAndClose()
    }

    private fun setupUI() {
        val messageTextView = findViewById<TextView>(R.id.blockingMessage)
        val timeTextView = findViewById<TextView>(R.id.remainingTime)
        val closeButton = findViewById<Button>(R.id.closeButton)

        // Get app display name
        val appName = try {
            val appInfo = packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(blockedPackage, 0)
            )
            appInfo.toString()
        } catch (e: Exception) {
            blockedPackage
        }

        messageTextView.text = "\"$appName\" is blocked!"

        if (strictMode) {
            closeButton.isEnabled = false
            closeButton.alpha = 0.5f
            closeButton.text = "Cannot close (Strict Mode)"
        } else {
            closeButton.text = "Close"
            closeButton.setOnClickListener {
                canClose = true
                finish()
            }
        }

        // Update remaining time
        updateRemainingTime(timeTextView)

        // Check time periodically
        val thread = Thread {
            while (!canClose && strictMode) {
                Thread.sleep(1000)
                val currentTime = System.currentTimeMillis()
                runOnUiThread {
                    if (currentTime >= endTime) {
                        canClose = true
                        closeButton.isEnabled = true
                        closeButton.alpha = 1.0f
                        closeButton.text = "Time's up! Close"
                        finish()
                    } else {
                        updateRemainingTime(timeTextView)
                    }
                }
            }
        }
        thread.start()
    }

    private fun updateRemainingTime(textView: TextView) {
        val currentTime = System.currentTimeMillis()
        val remainingMs = (endTime - currentTime).coerceAtLeast(0L)
        
        val seconds = (remainingMs / 1000) % 60
        val minutes = (remainingMs / (1000 * 60)) % 60
        val hours = (remainingMs / (1000 * 60 * 60)) % 24

        textView.text = String.format("Time remaining: %02d:%02d:%02d", hours, minutes, seconds)
    }

    private fun checkTimeAndClose() {
        val currentTime = System.currentTimeMillis()
        if (currentTime >= endTime && !strictMode) {
            canClose = true
            finish()
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Prevent back button from closing
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            return true
        }
        // Prevent home button in strict mode
        if (keyCode == KeyEvent.KEYCODE_HOME && strictMode) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onPause() {
        super.onPause()
        // Return to this activity immediately if it's paused
        if (!canClose) {
            val intent = Intent(this, BlockingActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            intent.putExtra("blocked_package", blockedPackage)
            intent.putExtra("strict_mode", strictMode)
            startActivity(intent)
        }
    }

    override fun onBackPressed() {
        // Do nothing - prevent back navigation
        if (!strictMode) {
            super.onBackPressed()
        }
    }
}
