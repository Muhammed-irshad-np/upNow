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

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.upnow/alarm_overlay"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "Configuring Flutter Engine and Method Channel")
        
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
                else -> {
                    Log.w("MainActivity", "Method ${call.method} not implemented.")
                    result.notImplemented()
                }
            }
        }

        // Set up basic notification handler
        setupNotificationHandler()
    }
    
    private fun setupNotificationHandler() {
        // Just log that we're ready to handle notifications
        Log.d("MainActivity", "Notification handler set up")
        // The actual launching happens via the Intent registered in the manifest
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
}
