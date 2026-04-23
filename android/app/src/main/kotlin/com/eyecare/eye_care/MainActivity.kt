package com.eyecare.eye_care

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eyecare/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNightSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open display settings", null)
                    }
                }
                "openDisplaySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open display settings", null)
                    }
                }
                "getScreenTimeMinutes" -> {
                    try {
                        val intent = Intent(this, ScreenTimeService::class.java)
                        startService(intent)
                        // Return current minutes (simplified - in production would bind to service)
                        val prefs = getSharedPreferences("eye_care_screen", MODE_PRIVATE)
                        val minutes = prefs.getInt("screen_time_today", 0)
                        result.success(minutes)
                    } catch (e: Exception) {
                        result.success(0)
                    }
                }
                "startScreenTracking" -> {
                    try {
                        val intent = Intent(this, ScreenTimeService::class.java)
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot start service", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}