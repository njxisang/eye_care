package com.eyecare.eye_care

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class ScreenStateReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_SCREEN_ON = "com.eyecare.SCREEN_ON"
        const val ACTION_SCREEN_OFF = "com.eyecare.SCREEN_OFF"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                sendBroadcast(context, ACTION_SCREEN_ON)
            }
            Intent.ACTION_SCREEN_OFF -> {
                sendBroadcast(context, ACTION_SCREEN_OFF)
            }
        }
    }

    private fun sendBroadcast(context: Context, action: String) {
        val broadcastIntent = Intent(action)
        broadcastIntent.setPackage(context.packageName)
        context.sendBroadcast(broadcastIntent)
    }
}
