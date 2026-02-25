package com.example.neki_app

import android.app_admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class SalahDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
    }
}
