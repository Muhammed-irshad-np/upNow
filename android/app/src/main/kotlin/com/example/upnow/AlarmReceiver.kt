package com.example.upnow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_ALARM_TRIGGERED = "com.example.upnow.ALARM_TRIGGERED"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm receiver triggered with action: ${intent.action}")
        
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
            if (intent.action == ACTION_ALARM_TRIGGERED || 
                intent.action == Intent.ACTION_BOOT_COMPLETED) {
                
                val alarmId = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_ID) ?: "unknown"
                val alarmLabel = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL) ?: "Alarm"
                val soundName = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND) ?: "alarm_sound"
                
                Log.d(TAG, "AlarmReceiver received broadcast for ID: $alarmId, Label: $alarmLabel, Sound: $soundName")
                
                // Skip launching for unknown IDs that aren't from a real alarm
                if (alarmId == "unknown_id") {
                    Log.d(TAG, "Skipping launch of AlarmActivity for unknown_id")
                    return
                }
                
                Log.d(TAG, "Launching AlarmActivity for alarm ID: $alarmId, Label: $alarmLabel")
                
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
            }
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