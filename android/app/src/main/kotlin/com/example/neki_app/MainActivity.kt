package com.clearwavesystems.nekiapp

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "neki/device_management"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, SalahDeviceAdminReceiver::class.java)

            when (call.method) {
                "lockDevice" -> {
                    if (devicePolicyManager.isAdminActive(adminComponent)) {
                        devicePolicyManager.lockNow()
                        result.success(true)
                    } else {
                        result.error("ADMIN_INACTIVE", "Device admin is not active", null)
                    }
                }
                "isDeviceAdminActive" -> {
                    result.success(devicePolicyManager.isAdminActive(adminComponent))
                }
                "requestDeviceAdmin" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Salah Lock Mode needs screen lock permission to keep you spiritually focused.")
                    startActivity(intent)
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                    val mode = appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
                    result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
                }
                "requestUsageStatsPermission" -> {
                    val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    result.success(android.provider.Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    intent.data = android.net.Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(true)
                }
                "startAppBlocker" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
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
                    stopService(Intent(this, AppBlockerService::class.java))
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
