package com.clearwavesystems.nekiapp

import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "neki/device_management"
    private val TAG = "SalahLock"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, SalahDeviceAdminReceiver::class.java)

            when (call.method) {
                "lockDevice" -> {
                    Log.d(TAG, "lockDevice called")
                    if (devicePolicyManager.isAdminActive(adminComponent)) {
                        Log.d(TAG, "Admin is active, calling lockNow()")
                        try {
                            devicePolicyManager.lockNow()
                            Log.d(TAG, "lockNow() succeeded")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "lockNow() failed: ${e.message}", e)
                            result.error("LOCK_FAILED", "Failed to lock device: ${e.message}", null)
                        }
                    } else {
                        Log.w(TAG, "Device admin is NOT active")
                        result.error("ADMIN_INACTIVE", "Device admin is not active", null)
                    }
                }
                "isDeviceAdminActive" -> {
                    val isActive = devicePolicyManager.isAdminActive(adminComponent)
                    Log.d(TAG, "isDeviceAdminActive = $isActive")
                    result.success(isActive)
                }
                "requestDeviceAdmin" -> {
                    Log.d(TAG, "requestDeviceAdmin called")
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Salah Lock Mode needs screen lock permission to keep you spiritually focused.")
                    startActivity(intent)
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                    val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
                    } else {
                        @Suppress("DEPRECATION")
                        appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
                    }
                    val hasPermission = mode == android.app.AppOpsManager.MODE_ALLOWED
                    Log.d(TAG, "checkUsageStatsPermission: mode=$mode, hasPermission=$hasPermission")
                    result.success(hasPermission)
                }
                "requestUsageStatsPermission" -> {
                    Log.d(TAG, "requestUsageStatsPermission called")
                    val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val hasPermission = android.provider.Settings.canDrawOverlays(this)
                    Log.d(TAG, "checkOverlayPermission = $hasPermission")
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    Log.d(TAG, "requestOverlayPermission called")
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    intent.data = android.net.Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(true)
                }
                "startAppBlocker" -> {
                    Log.d(TAG, "startAppBlocker called")
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    Log.d(TAG, "Starting app blocker for ${blockedApps.size} apps: $blockedApps")
                    val intent = Intent(this, AppBlockerService::class.java)
                    intent.putExtra("blockedApps", ArrayList(blockedApps))
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopAppBlocker" -> {
                    Log.d(TAG, "stopAppBlocker called")
                    stopService(Intent(this, AppBlockerService::class.java))
                    result.success(true)
                }
                "schedulePrayerAlarms" -> {
                    val prayerTimes = call.argument<List<Long>>("prayerTimes") ?: emptyList()
                    val prayerNames = call.argument<List<String>>("prayerNames") ?: emptyList()
                    
                    Log.d(TAG, "Scheduling ${prayerTimes.size} alarms")
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                    
                    for (i in prayerTimes.indices) {
                        val time = prayerTimes[i]
                        val name = prayerNames[i]
                        
                        val intent = Intent(this, SalahAlarmReceiver::class.java)
                        intent.action = "com.clearwavesystems.nekiapp.ACTION_PRAYER_ALARM"
                        intent.putExtra("salahName", name)
                        
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, i, intent, 
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                                if (alarmManager.canScheduleExactAlarms()) {
                                    alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, time, pendingIntent)
                                    Log.d(TAG, "Scheduled exact alarm for $name at $time")
                                } else {
                                    alarmManager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, time, pendingIntent)
                                    Log.d(TAG, "Scheduled inexact alarm for $name (exact permission missing)")
                                }
                            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                                alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, time, pendingIntent)
                                Log.d(TAG, "Scheduled exact alarm for $name at $time")
                            } else {
                                alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, time, pendingIntent)
                                Log.d(TAG, "Scheduled exact alarm for $name at $time")
                            }
                        } catch (e: SecurityException) {
                            Log.e(TAG, "SecurityException scheduling alarm: ${e.message}")
                            // Fallback to inexact if possible
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                                alarmManager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, time, pendingIntent)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error scheduling alarm: ${e.message}")
                        }
                    }
                    result.success(true)
                }
                "cancelPrayerAlarms" -> {
                    Log.d(TAG, "Cancelling all prayer alarms")
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                    for (i in 0..5) { // Assuming 5 prayers
                        val intent = Intent(this, SalahAlarmReceiver::class.java)
                        intent.action = "com.clearwavesystems.nekiapp.ACTION_PRAYER_ALARM"
                        val pendingIntent = PendingIntent.getBroadcast(
                            this, i, intent, 
                            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                        )
                        if (pendingIntent != null) {
                            alarmManager.cancel(pendingIntent)
                        }
                    }
                    result.success(true)
                }
                "checkExactAlarmPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                "requestExactAlarmPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        val intent = Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    Log.w(TAG, "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }
}
