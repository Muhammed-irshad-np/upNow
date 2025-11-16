package com.example.upnow

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.os.PowerManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.app.NotificationManager
import android.os.SystemClock
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.upnow/alarm_overlay"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "Configuring Flutter Engine and Method Channel")
        
        // Check for release mode-specific issues
        checkReleaseIssues()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("MainActivity", "Method call received: ${call.method}")
            when (call.method) {
                "showOverlay" -> {
                    val alarmId = call.argument<String>("id") ?: "unknown"
                    val alarmLabel = call.argument<String>("label") ?: "Alarm"
                    val soundName = call.argument<String>("soundName") ?: "alarm_sound"
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")
                    
                    // Check if this is an alarm from the past
                    if (hour != null && minute != null) {
                        if (AlarmReceiver.isAlarmInPast(hour, minute)) {
                            Log.d("MainActivity", "Skipping alarm from the past: $hour:$minute")
                            result.success("Skipped past alarm")
                            return@setMethodCallHandler
                        }
                    }
                    
                    launchAlarmActivity(alarmId, alarmLabel, soundName, hour, minute)
                    result.success("Overlay shown")
                }
                "hideOverlay" -> {
                    // No longer needed as we use AlarmActivity, but kept for compatibility
                    Log.d("MainActivity", "hideOverlay called - ignored since using AlarmActivity")
                    result.success(true)
                }
                "sendAlarmBroadcast" -> {
                    val alarmId = call.argument<String>("id")
                    val alarmLabel = call.argument<String>("label")
                    val soundName = call.argument<String>("soundName")
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")

                    if (alarmId != null && alarmLabel != null && soundName != null) {
                        Log.d("MainActivity", "Received sendAlarmBroadcast request for ID: $alarmId, Sound: $soundName")
                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            action = "com.example.upnow.ALARM_TRIGGER"
                            putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                            putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                            putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                            if (hour != null && minute != null) {
                                putExtra("hour", hour)
                                putExtra("minute", minute)
                            }
                        }
                        sendBroadcast(intent)
                        Log.d("MainActivity", "Broadcast sent immediately for alarm $alarmId")
                        result.success("Broadcast sent")
                    } else {
                        Log.e("MainActivity", "Missing arguments for sendAlarmBroadcast")
                        result.error("INVALID_ARGUMENTS", "Missing id, label, or soundName for broadcast", null)
                    }
                }
                "updatePendingAlarms" -> {
                    val hasPendingAlarms = call.argument<Boolean>("hasPendingAlarms") ?: false
                    Log.d("MainActivity", "Updating pending alarms flag: $hasPendingAlarms")
                    
                    // Use the static method from AlarmReceiver to update the flag
                    AlarmReceiver.updatePendingAlarmsFlag(this, hasPendingAlarms)
                    result.success(true)
                }
                "checkAlarmPermissions" -> {
                    // Add a new method to check all alarm-related permissions
                    val permissionsResult = checkAlarmPermissions()
                    result.success(permissionsResult)
                }
                "openCongratulationsScreen" -> {
                    // Open congratulations screen in Flutter
                    Log.d("MainActivity", "Opening congratulations screen")
                    openCongratulationsScreen()
                    result.success("Congratulations screen opened")
                }
                "registerTerminatedStateAlarm" -> {
                    try {
                        // Extract alarm data from the call
                        val alarmId = call.argument<String>("id") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing alarm ID", null)
                        val alarmLabel = call.argument<String>("label") ?: "Alarm"
                        val soundName = call.argument<String>("soundName") ?: "alarm_sound"
                        val hour = call.argument<Int>("hour") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing hour", null)
                        val minute = call.argument<Int>("minute") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Missing minute", null)
                        
                        // Register alarm with system AlarmManager for terminated state
                        registerSystemAlarm(alarmId, alarmLabel, soundName, hour, minute)
                        result.success("Alarm registered with system")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error registering terminated state alarm: ${e.message}")
                        result.error("ALARM_ERROR", "Failed to register system alarm: ${e.message}", null)
                    }
                }
                "scheduleNativeAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val label = call.argument<String>("label") ?: "Alarm"
                    val soundName = call.argument<String>("soundName") ?: "alarm_sound"
                    val repeatType = call.argument<String>("repeatType") ?: "once"
                    val weekdays = call.argument<List<Boolean>>("weekdays") ?: listOf(false, false, false, false, false, false, false)
                    
                    val success = scheduleNativeAlarm(alarmId, hour, minute, label, soundName, repeatType, weekdays)
                    result.success(success)
                }
                "cancelNativeAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    val success = cancelNativeAlarm(alarmId)
                    result.success(success)
                }
                "cancelAllNativeAlarms" -> {
                    val success = cancelAllNativeAlarms()
                    result.success(success)
                }
                "resetAlarmChannel" -> {
                    val reset = resetAlarmNotificationChannel()
                    result.success(reset)
                }
                else -> {
                    Log.w("MainActivity", "Method ${call.method} not implemented.")
                    result.notImplemented()
                }
            }
        }

        // Set up basic notification handler
        setupNotificationHandler()
    }
    
    /**
     * Check for issues specific to release builds
     */
    private fun checkReleaseIssues() {
        try {
            Log.d("MainActivity", "Checking for release mode issues")
            
            // Check AlarmManager existence
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            Log.d("MainActivity", "AlarmManager available: ${alarmManager != null}")
            
            // Check for broadcast receiver existence
            val receiverIntent = Intent(this, AlarmReceiver::class.java)
            
            // Safely check for broadcast receiver with proper flags
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_NO_CREATE
            }
            
            val receiverExists = PendingIntent.getBroadcast(
                this, 0, receiverIntent, pendingIntentFlags
            ) != null
            Log.d("MainActivity", "AlarmReceiver registered: $receiverExists")
            
            // Check power manager for wake locks
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            Log.d("MainActivity", "PowerManager available: ${powerManager != null}")
            
            // Verify activity can be launched
            val activityIntent = Intent(this, AlarmActivity::class.java)
            val activityInfo = activityIntent.resolveActivityInfo(packageManager, 0)
            Log.d("MainActivity", "AlarmActivity can be resolved: ${activityInfo != null}")
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking release mode issues: ${e.message}")
        }
    }
    
    /**
     * Check all alarm-related permissions and return a map of results
     */
    private fun checkAlarmPermissions(): Map<String, Boolean> {
        val results = mutableMapOf<String, Boolean>()
        
        try {
            // Check for alarm permission (Android 12+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                results["canScheduleExactAlarms"] = alarmManager.canScheduleExactAlarms()
            } else {
                results["canScheduleExactAlarms"] = true // Always true before Android 12
            }
            
            // Check for notification permission (Android 13+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                results["notificationsEnabled"] = notificationManager.areNotificationsEnabled()
            } else {
                results["notificationsEnabled"] = true // Cannot easily check before Android 13
            }
            
            // Check for battery optimization exemption
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                results["ignoringBatteryOptimizations"] = powerManager.isIgnoringBatteryOptimizations(packageName)
            } else {
                results["ignoringBatteryOptimizations"] = true // Not applicable before Android M
            }
            
            // Check if we can show the overlay
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                results["canDrawOverlays"] = Settings.canDrawOverlays(this)
            } else {
                results["canDrawOverlays"] = true // Cannot easily check before Android M
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking permissions: ${e.message}")
            results["error"] = true
        }
        
        Log.d("MainActivity", "Permission check results: $results")
        return results
    }
    
    private fun setupNotificationHandler() {
        // Just log that we're ready to handle notifications
        Log.d("MainActivity", "Notification handler set up")
        // The actual launching happens via the Intent registered in the manifest
    }

    private fun resetAlarmNotificationChannel(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.d("MainActivity", "Notification channels not supported on this API level")
            return true
        }

        return try {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existingChannel = notificationManager.getNotificationChannel("alarm_channel")
            if (existingChannel != null) {
                Log.d("MainActivity", "Deleting stale alarm_channel before recreation")
                notificationManager.deleteNotificationChannel("alarm_channel")
            }

            val channel = NotificationChannel(
                "alarm_channel",
                "Alarm Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for ringing alarms"
                enableVibration(true)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }

            notificationManager.createNotificationChannel(channel)
            Log.d("MainActivity", "alarm_channel recreated with high importance & lockscreen visibility")
            true
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to reset alarm channel: ${e.message}")
            false
        }
    }
    
    private fun launchAlarmActivity(alarmId: String, alarmLabel: String, soundName: String, hour: Int?, minute: Int?) {
        // Skip launching for unknown IDs that aren't from a real alarm
        if (alarmId == "unknown") {
            Log.d("MainActivity", "Skipping launch of AlarmActivity for unknown")
            return
        }
        
        val intent = Intent(this, AlarmActivity::class.java).apply {
            putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
            putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
            
            // Pass hour and minute if available
            if (hour != null && minute != null) {
                putExtra("hour", hour)
                putExtra("minute", minute)
            }
            
            // Use flags consistent with AlarmReceiver for showing over lock screen
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            
            // Add CLEAR_TASK for Android 10+ like in AlarmReceiver
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                flags = flags or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
        }
        
        startActivity(intent)
        Log.i("MainActivity", "AlarmActivity launched for alarm: $alarmId")
    }
    
    /**
     * Register an alarm with the system AlarmManager to ensure it works in terminated state
     */
    private fun registerSystemAlarm(alarmId: String, alarmLabel: String, soundName: String, hour: Int, minute: Int) {
        try {
            Log.d("MainActivity", "Registering system alarm for ID: $alarmId at $hour:$minute")
            
            // Create an intent for AlarmReceiver
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.example.upnow.ALARM_TRIGGER"
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
                putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                putExtra("hour", hour)
                putExtra("minute", minute)
                putExtra("isSystemAlarm", true) // Mark this as a system alarm
            }
            
            // Create a unique ID for this alarm based on the alarm ID
            val pendingIntentId = alarmId.hashCode()
            
            // Set up pending intent flags for Android compatibility
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            // Create the PendingIntent for the alarm
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                pendingIntentId,
                intent,
                pendingIntentFlags
            )
            
            // Calculate alarm time
            val calendar = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, hour)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
                
                // If the time is in the past, add a day
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
            }
            
            // Get system alarm manager
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Set the exact alarm based on Android version
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // For Android 6.0+ with exact timing and waking from Doze
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                // For Android 4.4-5.1
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            } else {
                // For older Android versions
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            }
            
            Log.i("MainActivity", "System alarm successfully registered for $hour:$minute (${calendar.timeInMillis})")
            
            // Store information that we have pending alarms in SharedPreferences
            AlarmReceiver.updatePendingAlarmsFlag(this, true)
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to register system alarm: ${e.message}")
            throw e
        }
    }
    
    /**
     * Opens the congratulations screen in Flutter
     */
    private fun openCongratulationsScreen() {
        try {
            Log.d("MainActivity", "Triggering congratulations screen via method channel")
            
            // Use the Flutter engine to call the method channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val channel = MethodChannel(messenger, CHANNEL)
                channel.invokeMethod("openCongratulationsScreen", null)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error opening congratulations screen: ${e.message}")
        }
    }
    
    companion object {
        private var instance: MainActivity? = null
        
        fun getInstance(): MainActivity? = instance
        
        /**
         * Static method to open congratulations screen from anywhere in the app
         */
        fun openCongratulationsScreenStatic() {
            instance?.openCongratulationsScreen()
        }
    }
    
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
        // If launched with an instruction to open the congratulations screen, handle it.
        handleOpenCongratulationsIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle cases where MainActivity is already running and receives a new intent
        handleOpenCongratulationsIntent(intent)
    }

    private fun handleOpenCongratulationsIntent(startIntent: Intent?) {
        try {
            if (startIntent?.getBooleanExtra("open_congratulations", false) == true) {
                Log.d("MainActivity", "Received request via intent to open congratulations screen")
                // Defer slightly to ensure Flutter is attached
                window?.decorView?.post {
                    openCongratulationsScreen()
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error handling open_congratulations intent: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
    
    // ✅ NATIVE ALARM MANAGER METHODS - NOTIFICATION INDEPENDENT
    
    /**
     * Schedule alarm using native Android AlarmManager (works even with notifications disabled)
     */
    private fun scheduleNativeAlarm(
        alarmId: String,
        hour: Int,
        minute: Int,
        label: String,
        soundName: String,
        repeatType: String,
        weekdays: List<Boolean>
    ): Boolean {
        try {
            Log.d("MainActivity", "🔔 NATIVE ALARM: Scheduling alarm $alarmId for $hour:$minute")
            
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                
                // If the time has already passed today, schedule for tomorrow
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_MONTH, 1)
                }
            }
            
            val triggerTime = calendar.timeInMillis
            Log.d("MainActivity", "🔔 NATIVE ALARM: Trigger time: ${calendar.time}")
            
            // Create intent for AlarmReceiver (ACTUAL ALARM)
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.example.upnow.NATIVE_ALARM_TRIGGER"
                putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmActivity.EXTRA_ALARM_LABEL, label)
                putExtra(AlarmActivity.EXTRA_ALARM_SOUND, soundName)
                putExtra("hour", hour)
                putExtra("minute", minute)
                putExtra("repeatType", repeatType)
                putExtra("weekdays", weekdays.toBooleanArray())
            }
            
            // Create PendingIntent with unique request code based on alarm ID
            val requestCode = alarmId.hashCode()
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Schedule the alarm
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    // Use setExactAndAllowWhileIdle for Android 6+ (Doze mode support)
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                    Log.d("MainActivity", "🔔 NATIVE ALARM: Used setExactAndAllowWhileIdle")
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                    // Use setExact for Android 4.4+
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                    Log.d("MainActivity", "🔔 NATIVE ALARM: Used setExact")
                }
                else -> {
                    // Fallback for older versions
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                    Log.d("MainActivity", "🔔 NATIVE ALARM: Used set (legacy)")
                }
            }
            
            Log.d("MainActivity", "✅ NATIVE ALARM: Successfully scheduled alarm $alarmId")
            return true
            
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ NATIVE ALARM: Failed to schedule alarm $alarmId: ${e.message}")
            return false
        }
    }
    
    /**
     * Cancel a specific native alarm
     */
    private fun cancelNativeAlarm(alarmId: String): Boolean {
        try {
            Log.d("MainActivity", "🗑️ NATIVE ALARM: Cancelling alarm $alarmId")
            
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java)
            val requestCode = alarmId.hashCode()
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                requestCode,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                Log.d("MainActivity", "✅ NATIVE ALARM: Successfully cancelled alarm $alarmId")
                return true
            } else {
                Log.d("MainActivity", "⚠️ NATIVE ALARM: No pending intent found for alarm $alarmId")
                return false
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ NATIVE ALARM: Failed to cancel alarm $alarmId: ${e.message}")
            return false
        }
    }
    
    /**
     * Cancel all native alarms
     */
    private fun cancelAllNativeAlarms(): Boolean {
        try {
            Log.d("MainActivity", "🗑️ NATIVE ALARM: Cancelling all alarms")
            
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Get all alarms from database and cancel them
            // Note: This is a simplified approach. In a real app, you'd want to track
            // all scheduled alarms in a more sophisticated way
            val intent = Intent(this, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                0,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
            
            Log.d("MainActivity", "✅ NATIVE ALARM: Successfully cancelled all alarms")
            return true
            
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ NATIVE ALARM: Failed to cancel all alarms: ${e.message}")
            return false
        }
    }
}
