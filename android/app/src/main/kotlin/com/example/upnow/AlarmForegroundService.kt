package com.example.upnow

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class AlarmForegroundService : Service() {

    companion object {
        private const val TAG = "AlarmForegroundService"
        private const val CHANNEL_ID = "alarm_channel"
        private const val ACTION_START = "com.example.upnow.action.START_ALARM"
        private const val ACTION_STOP = "com.example.upnow.action.STOP_ALARM"

        fun start(
            context: Context,
            alarmId: String,
            alarmLabel: String,
            soundName: String,
            hour: Int,
            minute: Int,
            repeatType: String,
            weekdays: BooleanArray?
        ) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                putExtra("hour", hour)
                putExtra("minute", minute)
                putExtra("repeatType", repeatType)
                putExtra("weekdays", weekdays)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context, alarmId: String?) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_STOP
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
            }
            ContextCompat.startForegroundService(context, intent)
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var currentAlarmId: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                Log.d(TAG, "Received stop action for alarm ${intent.getStringExtra(AlarmActivity.EXTRA_ALARM_ID)}")
                stopAlarmPlayback()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                handleStart(intent)
            }
            else -> Log.d(TAG, "Ignoring unknown action: ${intent.action}")
        }
        return START_STICKY
    }

    private fun handleStart(intent: Intent?) {
        val alarmId = intent?.getStringExtra(AlarmActivity.EXTRA_ALARM_ID) ?: "unknown"
        val alarmLabel = intent?.getStringExtra(AlarmActivity.EXTRA_ALARM_LABEL) ?: "Alarm"
        val soundName = intent?.getStringExtra(AlarmActivity.EXTRA_ALARM_SOUND) ?: "alarm_sound"
        val hour = intent?.getIntExtra("hour", -1) ?: -1
        val minute = intent?.getIntExtra("minute", -1) ?: -1
        val repeatType = intent?.getStringExtra("repeatType") ?: "once"
        val weekdays = intent?.getBooleanArrayExtra("weekdays")

        currentAlarmId = alarmId

        Log.d(TAG, "Starting foreground service for alarm $alarmId label=$alarmLabel sound=$soundName")

        acquireWakeLock()
        ensureNotificationChannel()
        startForeground(alarmId.hashCode(), buildNotification(alarmId, alarmLabel, soundName, repeatType, weekdays))
        startAlarmPlayback(soundName)
        maybeLaunchAlarmActivity(alarmId, alarmLabel, soundName, hour, minute, repeatType, weekdays)
    }

    private fun buildNotification(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        repeatType: String,
        weekdays: BooleanArray?
    ): Notification {
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
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
            this,
            alarmId.hashCode(),
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Check if full-screen intents are allowed (Android 10+)
        val canUseFullScreenIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.canUseFullScreenIntent() == true
        } else {
            true // Always allowed before Android 10
        }
        
        Log.d(TAG, "Full-screen intent capability: $canUseFullScreenIntent for alarm $alarmId")

        return NotificationCompat.Builder(this, CHANNEL_ID)
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

    private fun maybeLaunchAlarmActivity(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        hour: Int,
        minute: Int,
        repeatType: String,
        weekdays: BooleanArray?
    ) {
        val powerManager = getSystemService(PowerManager::class.java)
        val keyguardManager = getSystemService(KeyguardManager::class.java)
        val isInteractive = powerManager?.isInteractive == true
        val isLocked = keyguardManager?.isKeyguardLocked == true

        if (isInteractive && !isLocked) {
            Log.i(TAG, "Device unlocked; launching AlarmActivity directly for $alarmId")
            val intent = Intent(this, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_NO_HISTORY
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                putExtra("hour", hour)
                putExtra("minute", minute)
                putExtra("repeatType", repeatType)
                putExtra("weekdays", weekdays)
            }
            startActivity(intent)
        } else {
            Log.i(TAG, "Posting full-screen notification; system will surface AlarmActivity for $alarmId")
        }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            val existingChannel = notificationManager?.getNotificationChannel(CHANNEL_ID)
            
            // Always recreate channel with IMPORTANCE_MAX for full-screen intents to work reliably
            // This is especially important for OEMs like Realme that reset channel settings after reinstall
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Alerts",
                NotificationManager.IMPORTANCE_MAX // Changed from IMPORTANCE_HIGH to MAX for full-screen intents
            ).apply {
                description = "Alerts when an alarm is ringing"
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
                notificationManager?.deleteNotificationChannel(CHANNEL_ID)
                Log.d(TAG, "Deleted existing alarm channel to recreate with MAX importance")
            }
            
            notificationManager?.createNotificationChannel(channel)
            Log.d(TAG, "Created/updated alarm notification channel with IMPORTANCE_MAX")
            
            // Verify channel was created correctly
            val createdChannel = notificationManager?.getNotificationChannel(CHANNEL_ID)
            if (createdChannel != null) {
                Log.d(TAG, "Channel importance: ${createdChannel.importance}, canShowBadge: ${createdChannel.canShowBadge()}")
            }
        }
    }

    private fun startAlarmPlayback(soundName: String) {
        stopAlarmPlayback()

        try {
            val vibratorService = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator = vibratorService
            val vibrationPattern = longArrayOf(0, 500, 500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibratorService.vibrate(VibrationEffect.createWaveform(vibrationPattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibratorService.vibrate(vibrationPattern, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start vibration: ${e.message}")
        }

        try {
            var soundUri: Uri? = null
            if (soundName != "alarm_sound" && soundName.isNotEmpty()) {
                val resourceId = resources.getIdentifier(soundName, "raw", packageName)
                if (resourceId != 0) {
                    soundUri = Uri.parse("android.resource://$packageName/$resourceId")
                    Log.d(TAG, "Using custom alarm sound: $soundName")
                } else {
                    Log.w(TAG, "Custom sound '$soundName' not found, falling back to default")
                }
            }

            if (soundUri == null) {
                soundUri = android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmForegroundService, soundUri!!)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
            Log.d(TAG, "Alarm playback started via foreground service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start alarm playback: ${e.message}")
        }
    }

    private fun stopAlarmPlayback() {
        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping media player: ${e.message}")
        }
        mediaPlayer = null

        try {
            vibrator?.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping vibration: ${e.message}")
        }
        vibrator = null

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock: ${e.message}")
        }
        wakeLock = null

        currentAlarmId?.let {
            NotificationManagerCompat.from(this).cancel(it.hashCode())
        }
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "UpNow:AlarmForegroundWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire(10 * 60 * 1000L)
            }
            Log.d(TAG, "Wake lock acquired in foreground service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarmPlayback()
    }
}

