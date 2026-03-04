package com.clearwavesystems.nekiapp

import android.app.*
import android.app.usage.*
import android.content.*
import android.os.*
import androidx.core.app.NotificationCompat

class AppBlockerService : Service() {
    private var blockedApps = listOf<String>()
    private var handler = Handler(Looper.getMainLooper())
    private var checkInterval = 500L
    private val NOTIFICATION_ID = 888
    private val CHANNEL_ID = "AppBlockerChannel"
    private var isStrictMode = false
    private var isChecking = false

    private val checkRunnable = object : Runnable {
        override fun run() {
            if (!isChecking) return
            try {
                checkForegroundApp()
            } catch (e: Exception) {
                android.util.Log.e("AppBlocker", "Loop Error: ${e.message}")
            }
            handler.postDelayed(this, checkInterval)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val appsList = intent?.getStringArrayListExtra("blockedApps")
        if (appsList != null) {
            isStrictMode = appsList.contains("ALL_APPS_STRICT_MODE")
            blockedApps = appsList.filter { it != "ALL_APPS_STRICT_MODE" }
        }
        
        android.util.Log.d("AppBlocker", "🔥 Service Command: StrictMode=$isStrictMode, Apps=${blockedApps.size}")
        
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Salah Lock Active")
            .setContentText(if (isStrictMode) "Strict Lockdown is active." else "Distracting apps are blocked.")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        
        if (!isChecking) {
            isChecking = true
            handler.post(checkRunnable)
            android.util.Log.d("AppBlocker", "🚀 Loop started.")
        }
        
        return START_STICKY
    }

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        // 1. Get latest Activity events (last 1 minute)
        val usageEvents = usageStatsManager.queryEvents(time - 60000, time)
        val event = UsageEvents.Event()
        var currentFocusApp: String? = null
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            // We care about what just became active
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                currentFocusApp = event.packageName
            }
        }

        // 2. Fallback to usage stats for last 2 minutes if events are silent
        if (currentFocusApp == null) {
            val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 120000, time)
            currentFocusApp = stats?.maxByOrNull { it.lastTimeUsed }?.packageName
        }

        // 3. Evaluation
        if (currentFocusApp != null) {
            val myPackage = packageName
            
            // Log every 3 seconds to confirm monitor is alive
            if (time % 3000 < 500) {
                 android.util.Log.d("AppBlocker", "👁️ Monitoring focus: $currentFocusApp")
            }

            // Exceptions
            val isException = currentFocusApp == myPackage || 
                             currentFocusApp == "com.android.settings" || 
                             currentFocusApp == "com.android.systemui" ||
                             currentFocusApp == "com.android.dialer" ||
                             currentFocusApp == "com.google.android.dialer" ||
                             currentFocusApp.contains("launcher") || 
                             currentFocusApp.contains("packageinstaller") // Important for perms

            if (isException) return

            val shouldBlock = isStrictMode || blockedApps.contains(currentFocusApp)

            if (shouldBlock) {
                android.util.Log.w("AppBlocker", "🚨 BLOCKING: $currentFocusApp")
                launchBlockedActivity()
            }
        } else {
             if (time % 10000 < 500) {
                android.util.Log.e("AppBlocker", "❌ FAILED to detect focus app. Check Usage Permissions.")
            }
        }
    }

    private fun launchBlockedActivity() {
        val intent = Intent(this, BlockedActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                       Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                       Intent.FLAG_ACTIVITY_CLEAR_TOP)
        try {
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("AppBlocker", "Error showing block screen: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Salah Lock monitor", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        android.util.Log.d("AppBlocker", "🛑 Service Stopping.")
        isChecking = false
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }
}
