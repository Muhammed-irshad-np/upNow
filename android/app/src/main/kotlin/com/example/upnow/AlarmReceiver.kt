package com.example.upnow

import android.app.KeyguardManager
import android.app.Notification
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_ALARM_TRIGGERED = "com.example.upnow.ALARM_TRIGGERED"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
        private const val PREFS_NAME = "com.example.upnow.AlarmPrefs"
        private const val KEY_HAS_PENDING_ALARMS = "has_pending_alarms"
        private const val CHANNEL_ID = "upnow_alarm_channel_v2"
        
        // Call this when alarms are scheduled or all cleared
        fun updatePendingAlarmsFlag(context: Context, hasPendingAlarms: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_HAS_PENDING_ALARMS, hasPendingAlarms).apply()
            Log.d(TAG, "Updated pending alarms flag: $hasPendingAlarms")
        }
        
        // Check if a specific alarm is in the past based on hour and minute
        fun isAlarmInPast(hour: Int, minute: Int): Boolean {
            val now = Calendar.getInstance()
            val currentHour = now.get(Calendar.HOUR_OF_DAY)
            val currentMinute = now.get(Calendar.MINUTE)
            
            // Compare hours and minutes
            return (currentHour > hour) || (currentHour == hour && currentMinute > minute)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm receiver triggered with action: ${intent.action}")
        
        // Check if this is a direct alarm trigger, native alarm trigger, or boot completed event
        val isDirectAlarmTrigger = intent.action == "com.example.upnow.ALARM_TRIGGER"
        val isNativeAlarmTrigger = intent.action == "com.example.upnow.NATIVE_ALARM_TRIGGER"
        // Only proceed if this is a recognized action
        if (!isDirectAlarmTrigger && !isNativeAlarmTrigger) {
            Log.d(TAG, "Ignoring unknown action: ${intent.action}")
            return
        }
        
        // Handle both direct alarm trigger and native alarm trigger
        val alarmId = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_ID)
        val alarmLabel = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL) ?: "Alarm"
        val soundName = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND) ?: "alarm_sound"
        val hour = intent.getIntExtra("hour", -1)
        val minute = intent.getIntExtra("minute", -1)
        val repeatType = intent.getStringExtra("repeatType") ?: "once"
        val weekdays = intent.getBooleanArrayExtra("weekdays")
        val primaryColor = intent.getLongExtra("primaryColor", -1L)
        val primaryColorLight = intent.getLongExtra("primaryColorLight", -1L)
        val dismissType = intent.getStringExtra("dismissType") ?: "math"
        
        val triggerType = if (isNativeAlarmTrigger) "NATIVE ALARM" else "NOTIFICATION"
        Log.d(TAG, "🔔 $triggerType TRIGGER - ID: $alarmId, Label: $alarmLabel, Sound: $soundName, Type: $dismissType")
        
        // Only proceed if we have a valid alarm ID (not null and not "unknown")
        if (alarmId == null || alarmId == "unknown") {
            Log.d(TAG, "Ignoring alarm trigger without valid alarm ID")
            return
        }
        
        // Check if the alarm time has passed (if hour and minute are provided)
        if (hour != -1 && minute != -1) {
            // For app startup, do not show alarms from the past
            if (isAlarmInPast(hour, minute)) {
                Log.d(TAG, "⏰ Ignoring alarm that has already passed: $hour:$minute")
                return
            }
        }
        
        Log.d(TAG, "Dispatching alarm to foreground service -> ID: $alarmId, Label: $alarmLabel, Sound: $soundName")

        val powerManager = context.getSystemService(PowerManager::class.java)
        val keyguardManager = context.getSystemService(KeyguardManager::class.java)
        val isInteractive = powerManager?.isInteractive == true
        val isLocked = keyguardManager?.isKeyguardLocked == true

        Log.d(
            TAG,
            "Starting AlarmForegroundService (interactive=$isInteractive, locked=$isLocked) for $alarmId"
        )
        // 1. ALWAYS post notification first (Reliability Layer)
        // This ensures that even if the Service fails to start (background restrictions),
        // the user still sees a notification they can tap.
        val notification = buildNotification(
            context = context,
            alarmId = alarmId,
            alarmLabel = alarmLabel,
            soundName = soundName,
            repeatType = repeatType,
            weekdays = weekdays,
            primaryColor = if (primaryColor != -1L) primaryColor else null,
            primaryColorLight = if (primaryColorLight != -1L) primaryColorLight else null,
            dismissType = dismissType
        )
        
        try {
            // Use the same ID so the Service can "take over" this notification
            NotificationManagerCompat.from(context).notify(alarmId.hashCode(), notification)
            Log.d(TAG, "✅ Posted immediate notification for alarm $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to post immediate notification: ${e.message}")
        }

        // 2. Try to start the service (Sound/Vibration/Full Screen Activity Layer)
        try {
            AlarmForegroundService.start(
                context = context,
                alarmId = alarmId,
                alarmLabel = alarmLabel,
                soundName = soundName,
                hour = hour,
                minute = minute,
                repeatType = repeatType,
                weekdays = weekdays,
                primaryColor = if (primaryColor != -1L) primaryColor else null,
                primaryColorLight = if (primaryColorLight != -1L) primaryColorLight else null,
                dismissType = dismissType
            )
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start AlarmForegroundService: ${e.message}")
            // We already posted the notification, so the user is at least alerted.
        }
    }

    private fun buildNotification(
        context: Context,
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        repeatType: String,
        weekdays: BooleanArray?,
        primaryColor: Long?,
        primaryColorLight: Long?,
        dismissType: String
    ): Notification {
        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
            putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
            putExtra("repeatType", repeatType)
            putExtra("weekdays", weekdays)
            putExtra("service_started", true)
            
            // Pass theme colors
            primaryColor?.let { putExtra("primaryColor", it) }
            primaryColorLight?.let { putExtra("primaryColorLight", it) }
            putExtra("dismissType", dismissType)
        }

        val fullScreenIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(alarmLabel)
            .setContentText("Tap to solve and dismiss")
            .setPriority(NotificationCompat.PRIORITY_MAX)  // Changed from PRIORITY_MAX for consistency
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenIntent, true)  // Critical: true enables lockscreen launch
            .setContentIntent(fullScreenIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSound(null)  // Sound handled by service
            .setDefaults(0)  // No defaults, we control everything
            .setShowWhen(true)  // Show timestamp
            .setWhen(System.currentTimeMillis())  // Set current time
            .setTimeoutAfter(10 * 60 * 1000)  // Auto-dismiss after 10 minutes
            .build()
    }
} 