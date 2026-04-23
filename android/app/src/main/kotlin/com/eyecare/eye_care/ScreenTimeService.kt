package com.eyecare.eye_care

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.IBinder
import java.text.SimpleDateFormat
import java.util.*

class ScreenTimeService : Service() {
    private var screenOnTime: Long = 0
    private var lastScreenOn: Long = 0
    private var isScreenOn = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ScreenStateReceiver.ACTION_SCREEN_ON -> onScreenOn()
                ScreenStateReceiver.ACTION_SCREEN_OFF -> onScreenOff()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        loadTodayData()
        registerReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        saveTodayData()
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {}
    }

    private fun registerReceiver() {
        val filter = IntentFilter().apply {
            addAction(ScreenStateReceiver.ACTION_SCREEN_ON)
            addAction(ScreenStateReceiver.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)
    }

    private fun onScreenOn() {
        isScreenOn = true
        lastScreenOn = System.currentTimeMillis()
    }

    private fun onScreenOff() {
        if (isScreenOn && lastScreenOn > 0) {
            screenOnTime += System.currentTimeMillis() - lastScreenOn
            isScreenOn = false
            lastScreenOn = 0
            saveTodayData()
        }
    }

    fun getScreenOnMinutes(): Int {
        var total = screenOnTime
        if (isScreenOn && lastScreenOn > 0) {
            total += System.currentTimeMillis() - lastScreenOn
        }
        return (total / 60000).toInt()
    }

    private fun getTodayKey(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
    }

    private fun loadTodayData() {
        val prefs = getSharedPreferences("eye_care_screen", MODE_PRIVATE)
        val todayKey = getTodayKey()
        val savedDate = prefs.getString("date", "")
        if (savedDate == todayKey) {
            screenOnTime = prefs.getLong("screen_time_today", 0)
        } else {
            // New day, reset
            screenOnTime = 0
            prefs.edit()
                .putString("date", todayKey)
                .putLong("screen_time_today", 0)
                .apply()
        }
    }

    private fun saveTodayData() {
        val prefs = getSharedPreferences("eye_care_screen", MODE_PRIVATE)
        prefs.edit()
            .putString("date", getTodayKey())
            .putLong("screen_time_today", screenOnTime)
            .apply()
    }
}
