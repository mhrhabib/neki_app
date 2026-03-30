package com.clearwavesystems.nekiapp

import android.content.Context
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
            when (call.method) {
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
                        val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                    }
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }
}
