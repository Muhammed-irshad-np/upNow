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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class AlarmForegroundService : Service() {

    companion object {
        private const val TAG = "AlarmForegroundService"
        private const val CHANNEL_ID = "upnow_alarm_channel_v2"
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
            weekdays: BooleanArray?,
            primaryColor: Long? = null,
            primaryColorLight: Long? = null,
            dismissType: String = "math"
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
                
                // Pass theme colors
                primaryColor?.let { putExtra("primaryColor", it) }
                primaryColorLight?.let { putExtra("primaryColorLight", it) }
                putExtra("dismissType", dismissType)
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
    private val launchHandler = Handler(Looper.getMainLooper())
    private var pendingLaunchIntent: Intent? = null

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
        val primaryColor = intent?.getLongExtra("primaryColor", -1L) ?: -1L
        val primaryColorLight = intent?.getLongExtra("primaryColorLight", -1L) ?: -1L
        val dismissType = intent?.getStringExtra("dismissType") ?: "math"

        Log.d(TAG, "handleStart - AlarmId: $alarmId, DismissType: $dismissType")

        currentAlarmId = alarmId

        Log.d(TAG, "Starting foreground service for alarm $alarmId label=$alarmLabel sound=$soundName")

        acquireWakeLock()
        ensureNotificationChannel(if (primaryColor != -1L) primaryColor.toInt() else android.graphics.Color.RED)
        startForeground(alarmId.hashCode(), buildNotification(
            alarmId, alarmLabel, soundName, repeatType, weekdays,
            if (primaryColor != -1L) primaryColor else null,
            if (primaryColorLight != -1L) primaryColorLight else null,
            dismissType
        ))
        startAlarmPlayback(alarmId, alarmLabel, soundName, repeatType, weekdays, hour, minute,
            if (primaryColor != -1L) primaryColor else null,
            if (primaryColorLight != -1L) primaryColorLight else null
        )
        maybeLaunchAlarmActivity(alarmId, alarmLabel, soundName, hour, minute, repeatType, weekdays,
            if (primaryColor != -1L) primaryColor else null,
            if (primaryColorLight != -1L) primaryColorLight else null,
            dismissType
        )
    }

    private fun buildNotification(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        repeatType: String,
        weekdays: BooleanArray?,
        primaryColor: Long?,
        primaryColorLight: Long?,
        dismissType: String
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
            
            // Pass theme colors
            primaryColor?.let { putExtra("primaryColor", it) }
            primaryColorLight?.let { putExtra("primaryColorLight", it) }
        }

        val fullScreenIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(alarmLabel)
            .setContentText("Tap to solve and dismiss")
            .setPriority(NotificationCompat.PRIORITY_MAX)  // Match channel importance
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenIntent, true)  // Critical: true enables lockscreen launch
            .setContentIntent(fullScreenIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSound(null)  // Sound handled separately
            .setDefaults(0)  // No defaults, we control everything
            .setShowWhen(true)  // Show timestamp
            .setWhen(System.currentTimeMillis())  // Set current time
            .setTimeoutAfter(10 * 60 * 1000)  // Auto-dismiss after 10 minutes
            .build()
    }

    private fun maybeLaunchAlarmActivity(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        hour: Int,
        minute: Int,
        repeatType: String,
        weekdays: BooleanArray?,
        primaryColor: Long?,
        primaryColorLight: Long?,
        dismissType: String
    ) {
        val powerManager = getSystemService(PowerManager::class.java)
        val keyguardManager = getSystemService(KeyguardManager::class.java)
        val isInteractive = powerManager?.isInteractive == true
        val isLocked = keyguardManager?.isKeyguardLocked == true
        pendingLaunchIntent = buildAlarmActivityIntent(
            alarmId,
            alarmLabel,
            soundName,
            hour,
            minute,
            repeatType,
            weekdays,
            primaryColor,
            primaryColorLight,
            dismissType
        )
        Log.i(
            TAG,
            "Attempting to launch AlarmActivity (locked=${!isInteractive || isLocked}, interactive=$isInteractive) for $alarmId"
        )
        attemptLaunchAlarmActivity(reason = "initial")
        Log.i(TAG, "Initial AlarmActivity launch dispatched for $alarmId (no retry loop)")
    }

    private fun buildAlarmActivityIntent(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        hour: Int,
        minute: Int,
        repeatType: String,
        weekdays: BooleanArray?,
        primaryColor: Long?,
        primaryColorLight: Long?,
        dismissType: String
    ): Intent {
        return Intent(this, AlarmActivity::class.java).apply {
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
            putExtra("hour", hour)
            putExtra("minute", minute)
            putExtra("repeatType", repeatType)
            putExtra("weekdays", weekdays)
            putExtra("service_started", true)
            
            // Pass theme colors
            primaryColor?.let { putExtra("primaryColor", it) }
            primaryColorLight?.let { putExtra("primaryColorLight", it) }
            putExtra("dismissType", dismissType)
        }
    }

    private fun attemptLaunchAlarmActivity(reason: String) {
        val intent = pendingLaunchIntent ?: return
        try {
            startActivity(intent)
            Log.d(
                TAG,
                "AlarmActivity launch attempt ($reason) dispatched for ${intent.getStringExtra(AlarmActivity.EXTRA_ALARM_ID)}"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AlarmActivity ($reason): ${e.message}")
        }
    }

    private fun ensureNotificationChannel(lightColor: Int = android.graphics.Color.RED) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            val existingChannel = notificationManager?.getNotificationChannel(CHANNEL_ID)
            val needsCreate = existingChannel == null
            val needsWarning = existingChannel != null && (
                    existingChannel.importance < NotificationManager.IMPORTANCE_HIGH ||
                            existingChannel.lockscreenVisibility != Notification.VISIBILITY_PUBLIC ||
                            existingChannel.canBypassDnd().not() ||
                            existingChannel.lightColor != lightColor
                    )

            if (needsCreate || needsWarning) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Alarm Alerts",
                    NotificationManager.IMPORTANCE_MAX  // Changed from HIGH to MAX for ColorOS/Realme
                ).apply {
                    description = "Alerts when an alarm is ringing"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    enableVibration(true)
                    setSound(null, null)
                    setBypassDnd(true)
                    setShowBadge(false)  // Critical for ColorOS
                    enableLights(true)   // Enable LED lights
                    this.lightColor = lightColor
                }
                notificationManager?.createNotificationChannel(channel)
                Log.d(TAG, "Created/Updated alarm notification channel with lightColor=${Integer.toHexString(lightColor)}")
            }
        }
    }

    private fun startAlarmPlayback(
        alarmId: String,
        alarmLabel: String,
        soundName: String,
        repeatType: String,
        weekdays: BooleanArray?,
        hour: Int,
        minute: Int,
        primaryColor: Long?,
        primaryColorLight: Long?
    ) {
        stopAlarmPlayback()

        try {
            val vibratorService = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator = vibratorService
            // Start vibration
            if (vibrator?.hasVibrator() == true) {
                val pattern = longArrayOf(0, 1000, 1000)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }
            }

            // NUCLEAR OPTION: Force launch activity if we have overlay permission
            // This bypasses lockscreen restrictions on ColorOS/MIUI
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
                Log.d(TAG, "Overlay permission granted, FORCE LAUNCHING AlarmActivity directly")
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
                    putExtra("service_started", true)
                    putExtra("hour", hour)
                    putExtra("minute", minute)
                    
                    // Pass theme colors
                    primaryColor?.let { putExtra("primaryColor", it) }
                    primaryColorLight?.let { putExtra("primaryColorLight", it) }
                }
                startActivity(alarmIntent)
            } else {
                Log.w(TAG, "Overlay permission MISSING, relying on FullScreenIntent only")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start vibration or force launch activity: ${e.message}")
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
        launchHandler.removeCallbacksAndMessages(null)
        pendingLaunchIntent = null

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

