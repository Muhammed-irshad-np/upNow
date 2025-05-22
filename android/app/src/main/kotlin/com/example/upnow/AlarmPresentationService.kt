package com.example.upnow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmPresentationService : Service() {

    companion object {
        private const val TAG = "AlarmPresentationSvc"
        private const val NOTIFICATION_CHANNEL_ID = "alarm_presentation_service_channel"
        private const val NOTIFICATION_ID = 789 // Must be unique
        const val ACTION_SHOW_ALARM = "com.example.upnow.action.SHOW_ALARM"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var screenWakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var activityStartAttempts = 0
    private var alarmId: String? = null
    private var alarmLabel: String? = null
    private var soundName: String? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        createNotificationChannel()
        
        // Acquire partial wake lock to keep CPU running
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$TAG:WakeLock"
        )
        wakeLock?.setReferenceCounted(false)
        wakeLock?.acquire(10 * 60 * 1000L /* 10 minutes */)
        
        // Also acquire a full wake lock to turn on screen
        screenWakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "$TAG:ScreenWakeLock"
        )
        screenWakeLock?.acquire(30 * 1000L /* 30 seconds */)
        
        Log.d(TAG, "All wake locks acquired")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand received action: ${intent?.action}")
        
        if (intent?.action == ACTION_SHOW_ALARM) {
            alarmId = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_ID) ?: "unknown"
            alarmLabel = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL) ?: "Alarm"
            soundName = intent.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND)

            Log.i(TAG, "Starting foreground service to present alarm ID: $alarmId")

            // Create a PendingIntent for the notification that will launch AlarmActivity
            val pendingIntent = Intent(this, AlarmActivity::class.java).apply {
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                if (soundName != null) {
                    putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                }
                // Set flags using addFlags() instead of direct assignment
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }.let { notificationIntent ->
                PendingIntent.getActivity(
                    this, 
                    0, 
                    notificationIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            // Notification for the foreground service itself - with high priority and content intent
            val serviceNotification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Alarm Active")
                .setContentText("Tap to view alarm")
                .setTicker("Alarm is ringing!")
                // Using a default system icon as a placeholder
                .setSmallIcon(android.R.drawable.sym_def_app_icon)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(pendingIntent)
                .setFullScreenIntent(pendingIntent, true) // This is key for showing over lock screen
                .setOngoing(true)
                .build()

            startForeground(NOTIFICATION_ID, serviceNotification)
            
            // Schedule the first attempt to launch AlarmActivity - give system a moment 
            // to process the notification and wake up fully
            handler.postDelayed({ attemptLaunchAlarmActivity() }, 500)
        } else {
            Log.w(TAG, "Unknown action or null intent, stopping service.")
            stopSelf(startId)
        }
        
        return START_STICKY // Make service restart if killed, to ensure alarm is shown
    }
    
    private fun attemptLaunchAlarmActivity() {
        activityStartAttempts++
        Log.d(TAG, "Attempting to start AlarmActivity (attempt #$activityStartAttempts)")
        
        if (activityStartAttempts > 5) {
            Log.e(TAG, "Failed to launch AlarmActivity after multiple attempts")
            // We'll keep the service running so the notification stays active
            return
        }
        
        try {
            val alarmActivityIntent = Intent(this, AlarmActivity::class.java).apply {
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                if (soundName != null) {
                    putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                }
                // Crucial flags for launching over other activities
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_NO_HISTORY)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }
            }
            
            startActivity(alarmActivityIntent)
            Log.i(TAG, "AlarmActivity successfully started for alarm ID: $alarmId")
            
            // Keep the service alive for a few seconds to maintain the wake lock
            // and monitor for activity launch failures
            handler.postDelayed({
                Log.d(TAG, "Scheduled service stop after successful activity launch")
                stopSelf()
            }, 10000) // Keep service for 10 more seconds
        } catch (e: Exception) {
            Log.e(TAG, "Error starting AlarmActivity: ${e.message}", e)
            
            // Try again after a short delay
            handler.postDelayed({ attemptLaunchAlarmActivity() }, 1000)
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        handler.removeCallbacksAndMessages(null)
        
        // Release wake locks
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "WakeLock released")
            }
        }
        
        screenWakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "ScreenWakeLock released")
            }
        }
        
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // We are not binding to this service
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Alarm Presentation Service"
            val importance = NotificationManager.IMPORTANCE_HIGH // Higher importance for a better chance at showing
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, channelName, importance).apply {
                description = "Channel for the alarm presentation foreground service."
                setShowBadge(true)
                setBypassDnd(true) // Bypass Do Not Disturb
                enableLights(true)
                enableVibration(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created with HIGH importance")
        }
    }
} 