package com.clearwavesystems.nekiapp

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.*
import android.graphics.PixelFormat
import android.os.*
import android.view.*
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.*

class AppBlockerService : Service() {
    private var blockedApps = listOf<String>()
    private var handler = Handler(Looper.getMainLooper())
    private var checkInterval = 1000L
    private val NOTIFICATION_ID = 888
    private val CHANNEL_ID = "AppBlockerChannel"

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, checkInterval)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        blockedApps = intent?.getStringArrayListExtra("blockedApps") ?: emptyList()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Salah Lock Active")
            .setContentText("Monitoring applications to keep you focused.")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        handler.post(checkRunnable)
        return START_STICKY
    }

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 10000, time)
        
        if (stats != null && stats.isNotEmpty()) {
            val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
            val foregroundPackage = sortedStats[0].packageName
            
            if (blockedApps.contains(foregroundPackage)) {
                showBlockOverlay()
            }
        }
    }

    private fun showBlockOverlay() {
       val intent = Intent(this, BlockedActivity::class.java)
       intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
       intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
       startActivity(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "App Blocker Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }
}
