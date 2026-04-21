package com.eyecare.eye_care

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // 触发护眼提醒通知
        // 在真实实现中，这里会触发 flutter_local_notifications
    }
}
