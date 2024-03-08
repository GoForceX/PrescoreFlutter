package com.bjbybbs.prescore_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

class AutoStartReceiver : BroadcastReceiver() {
    override fun onReceive(context : Context, intent : Intent) {
        if (intent.action.equals(Intent.ACTION_BOOT_COMPLETED)) {
            val sharedPreferences: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            if(sharedPreferences.getBoolean("flutter.localSessionExist", false)) {
                if(sharedPreferences.getBoolean("flutter.enableWearService", false) || sharedPreferences.getBoolean("flutter.checkExams", false)) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(Intent(context, PrescoreService::class.java))
                    } else {
                        context.startService(Intent(context, PrescoreService::class.java))
                    }
                }
            }
        }
    }
}
