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
    private var activeSalahName: String? = null

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
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appsList = intent?.getStringArrayListExtra("blockedApps")
        
        if (appsList != null) {
            // Called from Flutter or Alarm Receiver - use provided list, also persist
            isStrictMode = appsList.contains("ALL_APPS_STRICT_MODE")
            blockedApps = appsList.filter { it != "ALL_APPS_STRICT_MODE" }
            activeSalahName = intent.getStringExtra("salahName")
        } else {
            // Restarted by Android (START_STICKY with null intent) - load from SharedPreferences
            android.util.Log.d("AppBlocker", "⚠️ Null intent (START_STICKY restart) - loading from SharedPreferences")
            isStrictMode = prefs.getBoolean("flutter.salah_lock_all_apps", false)
            val storedApps = prefs.getStringSet("flutter.salah_lock_blocked_apps", null)
            blockedApps = storedApps?.toList() ?: emptyList()
        }
        
        android.util.Log.d("AppBlocker", "🔥 Service Command: StrictMode=$isStrictMode, Salah=$activeSalahName, Apps count=${blockedApps.size}, Apps=$blockedApps")
        
        // Check if salah lock is even enabled
        val isEnabled = prefs.getBoolean("flutter.salah_lock_enabled", false)
        if (!isEnabled) {
            android.util.Log.d("AppBlocker", "❌ Salah lock is disabled. Stopping service.")
            stopSelf()
            return START_NOT_STICKY
        }
        
        createNotificationChannel()
        val notifText = when {
            isStrictMode -> "Strict Lockdown is active."
            blockedApps.isNotEmpty() -> "Distracting apps are blocked (${blockedApps.size} apps)."
            else -> "Salah Lock is monitoring activity."
        }
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Salah Lock Active")
            .setContentText(notifText)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        
        if (!isChecking) {
            isChecking = true
            handler.post(checkRunnable)
            android.util.Log.d("AppBlocker", "🚀 Monitoring loop started.")
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
                 // Check if we should still be running
                 if (!shouldContinueBlocking()) {
                     android.util.Log.d("AppBlocker", "✅ Window over or prayer done. Stopping service.")
                     stopSelf()
                     return
                 }
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

            // Reload settings dynamically to stay in sync with Flutter
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.salah_lock_enabled", true)
            if (!isEnabled) {
                stopSelf()
                return
            }
            
            // Refresh blocked apps in case they changed
            val freshStrictMode = prefs.getBoolean("flutter.salah_lock_all_apps", false)
            val freshAppsSet = prefs.getStringSet("flutter.salah_lock_blocked_apps", null)
            val freshApps = freshAppsSet?.toList() ?: emptyList()
            if (freshStrictMode != isStrictMode || freshApps != blockedApps) {
                isStrictMode = freshStrictMode
                blockedApps = freshApps
                android.util.Log.d("AppBlocker", "🔄 Reloaded settings: StrictMode=$isStrictMode, Apps=${blockedApps.size}")
            }

            val shouldBlock = isStrictMode || blockedApps.contains(currentFocusApp)

            if (shouldBlock) {
                android.util.Log.w("AppBlocker", "🚨 BLOCKING: $currentFocusApp")
                launchBlockedActivity()
            }
        } else {
             if (time % 10000 < 500) {
                android.util.Log.e("AppBlocker", "❌ FAILED to detect focus app. Check Usage Permissions.")
                // If we fail for too long, maybe stop self to avoid drain, but for now just keep trying
            }
        }
    }

    private fun shouldContinueBlocking(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.salah_lock_enabled", true)
        if (!isEnabled) return false

        // 1. Get Today's Key (Same logic as SalahLockRepositoryImpl.dart)
        val calendar = java.util.Calendar.getInstance()
        // Shift logical day by 4 hours backwards
        calendar.add(java.util.Calendar.HOUR_OF_DAY, -4)
        val year = calendar.get(java.util.Calendar.YEAR)
        val month = calendar.get(java.util.Calendar.MONTH) + 1
        val day = calendar.get(java.util.Calendar.DAY_OF_MONTH)
        val todayKey = "$year-$month-$day"
        
        // 2. Check if the SPECIFIC prayer that started this service is done
        activeSalahName?.let { prayer ->
            val key = "flutter.salah_lock_done_${prayer}_$todayKey"
            if (prefs.getBoolean(key, false)) {
                android.util.Log.d("AppBlocker", "✅ $prayer marked as completed. Stopping.")
                return false
            }
        }

        return true 
    }

    private fun launchBlockedActivity() {
        val intent = Intent(this, BlockedActivity::class.java)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_SINGLE_TOP or
            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
            Intent.FLAG_ACTIVITY_CLEAR_TOP
        )

        val pendingIntent = android.app.PendingIntent.getActivity(
            this,
            999,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        // On Android 10+, use full-screen notification to launch activity from background
        val channelId = "salah_lock_alert"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "Salah Lock Alert",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "App blocking notification"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        val notification = androidx.core.app.NotificationCompat.Builder(this, channelId)
            .setContentTitle("🔒 Salah Time")
            .setContentText("It's time for Salah. Apps are blocked.")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setCategory(androidx.core.app.NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(false)
            .setOngoing(false)
            .build()

        val notificationManager = getSystemService(android.app.NotificationManager::class.java)
        notificationManager?.notify(998, notification)

        // Also try direct startActivity as fallback (works on some OEMs)
        try {
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.w("AppBlocker", "Direct startActivity failed (expected on Android 10+): ${e.message}")
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
