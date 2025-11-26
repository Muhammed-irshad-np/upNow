package com.example.upnow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootCompletedReceiver", "Ignoring action: ${intent?.action}")
            return
        }

        val prefs = context.getSharedPreferences(
            "com.example.upnow.AlarmPrefs",
            Context.MODE_PRIVATE
        )
        val hasPendingAlarms = prefs.getBoolean("has_pending_alarms", false)

        if (!hasPendingAlarms) {
            Log.d("BootCompletedReceiver", "Boot completed but no pending alarms, ignoring")
            return
        }

        Log.d(
            "BootCompletedReceiver",
            "Boot completed with pending alarms, letting Flutter handle rescheduling"
        )
        // No direct service start here; Flutter will reschedule when the app starts.
    }
}

