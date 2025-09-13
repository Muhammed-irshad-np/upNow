package com.example.upnow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import android.content.SharedPreferences
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_ALARM_TRIGGERED = "com.example.upnow.ALARM_TRIGGERED"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
        private const val PREFS_NAME = "com.example.upnow.AlarmPrefs"
        private const val KEY_HAS_PENDING_ALARMS = "has_pending_alarms"
        
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
        val alarmLabel = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL)
        val soundName = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND)
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
        
        // Acquire wake lock to ensure device is awake
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "UpNow:AlarmWakeLock"
        )
        
        // Acquire wake lock with timeout (release after 10 minutes)
        wakeLock.acquire(10 * 60 * 1000L)
        
        try {
            val alarmLabel = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL) ?: "Alarm"
            val soundName = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND) ?: "alarm_sound"
            
            Log.d(TAG, "Processing alarm for ID: $alarmId, Label: $alarmLabel, Sound: $soundName")
            
            // Launch AlarmActivity with all necessary flags to show over lock screen
            val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                
                // These flags are crucial for showing over lock screen and other apps
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_NO_HISTORY
                
                // For Android 10+ add this to immediately show over other activities
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    flags = flags or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
            }
            
            // Start the activity immediately
            context.startActivity(alarmIntent)
            Log.i(TAG, "AlarmActivity started from receiver for alarm ID: $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Error launching alarm activity: ${e.message}", e)
        } finally {
            // Release the wake lock to avoid battery drain
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }
} 