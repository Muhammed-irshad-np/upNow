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
                    val args = call.arguments as? Map<String, Any>
                    val alarmId = args?.get("id") as? String ?: "unknown_id"
                    val alarmLabel = args?.get("label") as? String ?: "Alarm"
                    Log.d("MainActivity", "showOverlay called with ID: $alarmId, Label: $alarmLabel")
                    
                    // Launch AlarmActivity instead of showing overlay
                    launchAlarmActivity(alarmId, alarmLabel)
                    result.success(true)
                }
                "hideOverlay" -> {
                    // No longer needed as we use AlarmActivity, but kept for compatibility
                    Log.d("MainActivity", "hideOverlay called - ignored since using AlarmActivity")
                    result.success(true)
                }
                "sendAlarmBroadcast" -> {
                    // Send a broadcast to the AlarmReceiver to launch the AlarmActivity
                    val args = call.arguments as? Map<String, Any>
                    val alarmId = args?.get("id") as? String ?: "unknown_id"
                    val alarmLabel = args?.get("label") as? String ?: "Alarm"
                    sendAlarmBroadcast(alarmId, alarmLabel)
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
    
    private fun sendAlarmBroadcast(alarmId: String, alarmLabel: String) {
        val intent = Intent(AlarmReceiver.ACTION_ALARM_TRIGGERED).apply {
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, alarmLabel)
        }
        sendBroadcast(intent)
        Log.i("MainActivity", "Sent alarm broadcast for alarm: $alarmId")
    }
    
    private fun setupNotificationHandler() {
        // Just log that we're ready to handle notifications
        Log.d("MainActivity", "Notification handler set up")
        // The actual launching happens via the Intent registered in the manifest
    }
    
    private fun launchAlarmActivity(alarmId: String, alarmLabel: String) {
        // Skip launching for unknown IDs that aren't from a real alarm
        if (alarmId == "unknown_id") {
            Log.d("MainActivity", "Skipping launch of AlarmActivity for unknown_id")
            return
        }
        
        val intent = Intent(this, AlarmActivity::class.java).apply {
            putExtra(AlarmActivity.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmActivity.EXTRA_ALARM_LABEL, alarmLabel)
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
