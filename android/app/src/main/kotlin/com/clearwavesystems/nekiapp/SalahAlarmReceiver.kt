package com.clearwavesystems.nekiapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class SalahAlarmReceiver : BroadcastReceiver() {
    private val TAG = "SalahAlarmReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "onReceive: action=$action")

        if (Intent.ACTION_BOOT_COMPLETED == action) {
            // Ideally reschedule here, but we need the prayer times from SharedPreferences
            // For now, we'll assume the app will be opened or we can trigger a check
            Log.d(TAG, "Device rebooted. Waiting for app to refresh alarms.")
        } else if ("com.clearwavesystems.nekiapp.ACTION_PRAYER_ALARM" == action) {
            val prayerName = intent.getStringExtra("salahName") ?: "Salah"
            Log.d(TAG, "⏰ Alarm triggered for $prayerName")

            // Start the AppBlockerService
            val serviceIntent = Intent(context, AppBlockerService::class.java)
            
            // We need to fetch the blocked apps from SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val blockedAppsSet = prefs.getStringSet("flutter.salah_lock_blocked_apps", null)
            val blockedApps = blockedAppsSet?.toList() ?: emptyList<String>()
            val lockAllApps = prefs.getBoolean("flutter.salah_lock_all_apps", false)
            
            val appsList = ArrayList(blockedApps)
            if (lockAllApps) {
                appsList.add("ALL_APPS_STRICT_MODE")
            }
            serviceIntent.putStringArrayListExtra("blockedApps", appsList)
            serviceIntent.putExtra("salahName", prayerName)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
