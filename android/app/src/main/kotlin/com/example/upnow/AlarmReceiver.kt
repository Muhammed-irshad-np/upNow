package com.example.upnow

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
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
        private const val CHANNEL_ID = "alarm_channel"
        
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
        val isBootCompleted = intent.action == Intent.ACTION_BOOT_COMPLETED

        // Only proceed if this is a recognized action
        if (!isDirectAlarmTrigger && !isNativeAlarmTrigger && !isBootCompleted) {
            Log.d(TAG, "Ignoring unknown action: ${intent.action}")
            return
        }
        
        // If it's a boot completed event, check if we have any pending alarms
        if (isBootCompleted) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val hasPendingAlarms = prefs.getBoolean(KEY_HAS_PENDING_ALARMS, false)
            
            if (!hasPendingAlarms) {
                Log.d(TAG, "Boot completed but no pending alarms, ignoring")
                return
            }
            
            // Continue with boot handling in the Flutter app
            // Return early - don't show the alarm screen yet
            // The Flutter app will schedule proper alarms after boot
            Log.d(TAG, "Boot completed with pending alarms, letting Flutter handle it")
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
        
        val triggerType = if (isNativeAlarmTrigger) "NATIVE ALARM" else "NOTIFICATION"
        Log.d(TAG, "🔔 $triggerType TRIGGER - ID: $alarmId, Label: $alarmLabel, Sound: $soundName, Time: $hour:$minute")
        
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



        if (!isInteractive || isLocked) {
            Log.d(TAG, "Device locked or screen off; posting notification for $alarmId")
            val notification = buildNotification(
                context = context,
                alarmId = alarmId,
                alarmLabel = alarmLabel,
                soundName = soundName,
                repeatType = repeatType,
                weekdays = weekdays
            )
            NotificationManagerCompat.from(context).notify(alarmId.hashCode(), notification)
        } else {
                    AlarmForegroundService.start(
            context = context,
            alarmId = alarmId,
            alarmLabel = alarmLabel,
            soundName = soundName,
            hour = hour,
            minute = minute,
            repeatType = repeatType,
            weekdays = weekdays
        )
            Log.d(TAG, "Device unlocked; foreground service will surface AlarmActivity")
        }
    }

    private fun buildNotification(
        context: Context,
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        repeatType: String,
        weekdays: BooleanArray?
    ): Notification {
        // Ensure notification channel exists with IMPORTANCE_MAX
        ensureNotificationChannel(context)
        
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
        }

        val fullScreenIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Check if full-screen intents are allowed (Android 10+)
        val canUseFullScreenIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.canUseFullScreenIntent()
        } else {
            true // Always allowed before Android 10
        }
        
        Log.d(TAG, "Full-screen intent capability: $canUseFullScreenIntent for alarm $alarmId")

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(alarmLabel)
            .setContentText("Tap to solve and dismiss")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenIntent, canUseFullScreenIntent) // Only set if allowed
            .setContentIntent(fullScreenIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSound(null)
            .setDefaults(0)
            .build()
    }
    
    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existingChannel = notificationManager.getNotificationChannel(CHANNEL_ID)
            
            // Always recreate channel with IMPORTANCE_MAX for full-screen intents to work reliably
            // This is especially important for OEMs like Realme that reset channel settings after reinstall
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Alerts",
                NotificationManager.IMPORTANCE_MAX // Changed from IMPORTANCE_HIGH to MAX for full-screen intents
            ).apply {
                description = "Channel for ringing alarms"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
                setSound(null, null)
                setBypassDnd(true)
                // Ensure full-screen intent capability
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    setAllowBubbles(false)
                }
            }
            
            // Delete existing channel if it exists to ensure fresh settings
            if (existingChannel != null) {
                notificationManager.deleteNotificationChannel(CHANNEL_ID)
                Log.d(TAG, "Deleted existing alarm channel to recreate with MAX importance")
            }
            
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Created/updated alarm notification channel with IMPORTANCE_MAX")
            
            // Verify channel was created correctly
            val createdChannel = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (createdChannel != null) {
                Log.d(TAG, "Channel importance: ${createdChannel.importance}, canShowBadge: ${createdChannel.canShowBadge()}")
            }
        }
    }
} 