package com.bjbybbs.prescore_flutter

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
/*
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
*/
import com.bjbybbs.prescore_flutter.util.WearEngine

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

fun startService(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(Intent(context, PrescoreService::class.java))
    } else {
        context.startService(Intent(context, PrescoreService::class.java))
    }
}

fun stopService(context: Context) {
    context.stopService(Intent(context, PrescoreService::class.java))
}

class MainActivity: FlutterActivity() {
    /*private fun ignoringBatteryOptimizations() {
        val intent = Intent()
        val packageName: String = context.packageName
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
            intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            intent.data = Uri.parse("package:$packageName")
            context.startActivity(intent)
        }
    }*/
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val sharedPreferences: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val wearEngine = WearEngine()
        try {
            wearEngine.initClient(applicationContext)
        } catch(_: Exception) {}
        val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "MainActivity")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getBoundDevices"){
                wearEngine.requestPermission(this)
                fun onResult(msg: String) {
                    if(msg == "success") {
                        val deviceList = ArrayList<Map<String, String>>()
                        if(wearEngine.deviceList.isNotEmpty()) {
                            for(device in wearEngine.deviceList) {
                                deviceList.add(mapOf(device.uuid to device.name))
                            }
                        }
                        result.success(deviceList)
                    } else {
                        result.error("failed", msg, null)
                    }
                }
                wearEngine.getBoundDevices(::onResult)
            } else if (call.method == "startService"){
                try {
                    if (sharedPreferences.getBoolean("flutter.enableWearService", false)) {
                        wearEngine.requestPermission(this)
                        //ignoringBatteryOptimizations()
                    }
                } catch (_: Exception) {}
                val intent = Intent(context, PrescoreService::class.java)
                if (call.arguments != null) {
                    (call.arguments as Map<String, Any?>).forEach {
                        if(it.value is Boolean) {
                            intent.putExtra(it.key, it.value as Boolean)
                        }
                        if(it.value is Int) {
                            intent.putExtra(it.key, it.value as Int)
                        }
                        if(it.value is Long) {
                            intent.putExtra(it.key, it.value as Int)
                        }
                        if(it.value is String) {
                            intent.putExtra(it.key, it.value as String)
                        }
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } else if (call.method == "stopService"){
                stopService(applicationContext)
            }
        }
    }
}
