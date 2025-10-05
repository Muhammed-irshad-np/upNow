import 'dart:async';
import 'package:flutter/services.dart'; // Import for Platform Channel
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
// import 'package:upnow/screens/alarm/alarm_ring_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
// import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/utils/navigation_service.dart';

// Define a global variable to hold the current app lifecycle state
AppLifecycleState currentAppState = AppLifecycleState.resumed;

class AlarmService {
  static bool _isInitialized = false;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Define the platform channel
  static const MethodChannel _platformChannel = 
      MethodChannel('com.example.upnow/alarm_overlay');

  // Method to hide the overlay via platform channel
  static Future<void> hideOverlay() async {
     try {
      debugPrint('📱 ALARM OVERLAY: Requesting to hide overlay.');
      await _platformChannel.invokeMethod('hideOverlay');
      debugPrint('📱 ALARM OVERLAY: hideOverlay method invoked.');
    } on PlatformException catch (e) {
      debugPrint("📱 ALARM OVERLAY: Failed to invoke hideOverlay: '${e.message}'.");
    } catch (e) {
       debugPrint("📱 ALARM OVERLAY: Generic error invoking hideOverlay: $e");
    }
  }
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    debugPrint('ALARM SERVICE: Initializing alarm service...');
    
    // Set up method channel handler for native calls
    _platformChannel.setMethodCallHandler(_handleMethodCall);
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Request permissions first
    await requestPermissions();
    
    // Fix release mode issues
    final bool isReleaseMode = const bool.fromEnvironment('dart.vm.product');
    if (isReleaseMode) {
      debugPrint('ALARM SERVICE: Running in release mode - applying fixes');
      await fixReleasePermissions();
    }
    
    // ✅ CRITICAL FIX: Smart cleanup of expired notifications before initialization
    await _smartCleanupExpiredNotifications();
    
    // Create notification channels with high importance
    List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Notifications',
        description: 'Channel for alarm notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        playSound: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'alarm_focus',
        'Alarm Focus',
        description: 'High priority alarm notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        playSound: true,
        enableLights: true,
        showBadge: true,
      ),
    ];

    // Initialize the plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    _isInitialized = true;
    debugPrint('ALARM SERVICE: Initialization complete');
    
    // Schedule all existing alarms
    await _scheduleAllAlarms();
  }
  
  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final alarmId = response.payload!;
      final alarm = HiveDatabase.getAlarm(alarmId);
      
      if (alarm != null) {
        // Launch the alarm screen
        await _sendAlarmBroadcast(alarm);
      }
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'alarmTriggered':
        final alarmId = call.arguments['alarmId'] as String?;
        final alarmLabel = call.arguments['alarmLabel'] as String?;
        final soundName = call.arguments['soundName'] as String?;
        
        if (alarmId != null && alarmLabel != null && soundName != null) {
          final alarm = HiveDatabase.getAlarm(alarmId);
          if (alarm != null) {
            await _sendAlarmBroadcast(alarm);
          }
        }
        break;
      default:
        if (call.method == 'openCongratulationsScreen') {
          try {
            final state = navigationKey.currentState;
            if (state != null) {
              state.pushNamedAndRemoveUntil('/congratulations', (route) => false);
              debugPrint('🎉 Navigated to congratulations screen');
            } else {
              debugPrint('⚠️ Navigator not ready; deferring congratulations navigation');
              // Optionally, you could queue a microtask to retry shortly
            }
          } catch (e) {
            debugPrint('❌ Error navigating to congratulations: $e');
          }
        } else {
          debugPrint('📱 ALARM SERVICE: Unknown method call: ${call.method}');
        }
    }
  }

  // Method to update the pending alarms flag in the native platform
  static Future<void> _updatePendingAlarmsFlag(bool hasPendingAlarms) async {
    try {
      debugPrint('📱 ALARM SERVICE: Updating pending alarms flag: $hasPendingAlarms');
      await _platformChannel.invokeMethod('updatePendingAlarms', {
        'hasPendingAlarms': hasPendingAlarms,
      });
      debugPrint('📱 ALARM SERVICE: Successfully updated pending alarms flag');
    } on PlatformException catch (e) {
      debugPrint("📱 ALARM SERVICE: Failed to update pending alarms flag: '${e.message}'.");
    } catch (e) {
      debugPrint("📱 ALARM SERVICE: Generic error updating pending alarms flag: $e");
    }
  }
  
  // ✅ CRITICAL FIX: Smart cleanup of expired notifications
  static Future<void> _smartCleanupExpiredNotifications() async {
    try {
      debugPrint('🧹 ALARM SERVICE: Starting smart notification cleanup...');
      
      // Get all pending notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      debugPrint('📋 Found ${pendingNotifications.length} pending notifications');
      
      final now = DateTime.now();
      int cancelledCount = 0;
      int deletedOneTimeAlarms = 0;
      
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          final alarmId = notification.payload!;
          final alarm = HiveDatabase.getAlarm(alarmId);
          
          if (alarm != null) {
            // Calculate when this notification was supposed to fire
            final alarmTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
            
            if (alarmTime.isBefore(now)) {
              // Cancel the expired notification
              await _notifications.cancel(notification.id);
              cancelledCount++;
              debugPrint('🗑️ Cancelled expired notification for alarm ${alarm.hour}:${alarm.minute}');
              
              // Handle based on alarm type
        if (alarm.repeat == AlarmRepeat.once) {
                // For one-time alarms, delete from database
                await HiveDatabase.deleteAlarm(alarmId);
                deletedOneTimeAlarms++;
                debugPrint('🗑️ Deleted expired one-time alarm from database');
              } else {
                // For recurring alarms, log missed occurrence but keep alarm
                debugPrint('⏭️ Recurring alarm missed: ${alarm.hour}:${alarm.minute} (${alarm.repeat})');
              }
            } else {
              debugPrint('✅ Keeping valid notification for alarm ${alarm.hour}:${alarm.minute}');
            }
          }
        }
      }
      
      debugPrint('🧹 ALARM SERVICE: Cleanup complete. Cancelled $cancelledCount notifications, deleted $deletedOneTimeAlarms one-time alarms');
      
    } catch (e) {
      debugPrint('⚠️ ALARM SERVICE: Error during smart cleanup: $e');
      // Fallback: cancel all if cleanup fails
      try {
        await _notifications.cancelAll();
        debugPrint('🔄 ALARM SERVICE: Fallback - cancelled all notifications');
      } catch (fallbackError) {
        debugPrint('❌ ALARM SERVICE: Fallback cleanup also failed: $fallbackError');
      }
    }
  }
  
  static Future<void> _scheduleAllAlarms() async {
    final alarms = HiveDatabase.getAllAlarms();
    debugPrint('📋 Found ${alarms.length} alarms in database');
    
    // ✅ Additional validation: Clean up any remaining expired one-time alarms
    final now = DateTime.now();
    final List<String> alarmsToDelete = [];
    
    for (final alarm in alarms) {
      if (alarm.repeat == AlarmRepeat.once) {
        final alarmTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
        if (alarmTime.isBefore(now)) {
          alarmsToDelete.add(alarm.id);
          debugPrint('🗑️ Marking expired one-time alarm for deletion: ${alarm.hour}:${alarm.minute}');
        }
      }
    }
    
    // Delete expired one-time alarms
    for (final alarmId in alarmsToDelete) {
      await HiveDatabase.deleteAlarm(alarmId);
      debugPrint('✅ Deleted expired one-time alarm from database');
    }
    
    // Get updated list after cleanup
    final updatedAlarms = HiveDatabase.getAllAlarms();
    debugPrint('📅 Scheduling ${updatedAlarms.length} valid alarms');
    
    // Update the flag to indicate we have pending alarms
    await _updatePendingAlarmsFlag(updatedAlarms.any((alarm) => alarm.isEnabled));
    
    for (final alarm in updatedAlarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
  
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    try {
      debugPrint('🔔 SCHEDULING ALARM: Starting...');
      // Get the current time for logging purposes
      final DateTime now = DateTime.now();
      final tz.TZDateTime tzNow = tz.TZDateTime.from(now, tz.local);
      debugPrint('🔔 Current time: ${tzNow.toString()}');
      
      // ✅ CRITICAL FIX: Use getNextAlarmTime() for proper next occurrence calculation
      final nextOccurrence = alarm.getNextAlarmTime();
      debugPrint('🔔 Next occurrence calculated: ${nextOccurrence.toString()}');
      
      // ✅ Validate that next occurrence is in the future
      if (nextOccurrence.isBefore(now)) {
        debugPrint('❌ Calculated next occurrence is still in the past, not scheduling');
        return;
      }
      
      var scheduledDate = nextOccurrence;
      debugPrint('🔔 Final scheduled date: ${scheduledDate.toString()}');
      
      // ✅ SCHEDULE NATIVE ALARM (Primary - Bulletproof)
      await _scheduleNativeAlarm(alarm, scheduledDate);
      
      // ✅ SCHEDULE NOTIFICATION ALARM (Backup/UI indicator)
      await _scheduleNotificationAlarm(alarm, scheduledDate);
      
      debugPrint('✅ ALARM SCHEDULED: Both native alarm and notification scheduled');
         } catch (e) {
      debugPrint('❌ ERROR SCHEDULING ALARM: $e');
    }
  }
  
  // ✅ NATIVE ALARM SCHEDULING - PRIMARY BULLETPROOF SYSTEM
  static Future<void> _scheduleNativeAlarm(AlarmModel alarm, DateTime scheduledDate) async {
    try {
      debugPrint('🔔 NATIVE ALARM: Scheduling bulletproof native alarm for ${alarm.hour}:${alarm.minute}');
      
      // Check native alarm permissions first
      if (!await hasNativeAlarmPermissions()) {
        debugPrint('❌ NATIVE ALARM: Missing SCHEDULE_EXACT_ALARM permission, requesting...');
        if (!await requestNativeAlarmPermissions()) {
          debugPrint('❌ NATIVE ALARM: Permission denied, falling back to notification-only');
          return;
        }
      }
      
      // Convert repeat type to string
      String repeatType = 'once';
      switch (alarm.repeat) {
        case AlarmRepeat.daily:
          repeatType = 'daily';
          break;
        case AlarmRepeat.weekdays:
          repeatType = 'weekdays';
          break;
        case AlarmRepeat.weekends:
          repeatType = 'weekends';
          break;
        case AlarmRepeat.custom:
          repeatType = 'custom';
          break;
        case AlarmRepeat.once:
          repeatType = 'once';
          break;
      }
      
      // Schedule native alarm via platform channel (ACTUAL ALARM, not notification)
      final result = await _platformChannel.invokeMethod('scheduleNativeAlarm', {
        'alarmId': alarm.id,
            'hour': alarm.hour,
            'minute': alarm.minute,
        'label': alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        'soundName': alarm.soundPath.isNotEmpty ? p.basenameWithoutExtension(alarm.soundPath) : 'alarm_sound',
        'repeatType': repeatType,
        'weekdays': alarm.weekdays,
      });
      
      if (result == true) {
        debugPrint('✅ NATIVE ALARM: Successfully scheduled bulletproof native alarm');
      } else {
        debugPrint('❌ NATIVE ALARM: Failed to schedule native alarm');
      }
        } catch (e) {
      debugPrint('❌ NATIVE ALARM: Error scheduling native alarm: $e');
    }
  }
  
  // ✅ NOTIFICATION ALARM SCHEDULING - BACKUP/UI INDICATOR
  static Future<void> _scheduleNotificationAlarm(AlarmModel alarm, DateTime scheduledDate) async {
    try {
      debugPrint('🔔 NOTIFICATION ALARM: Scheduling notification alarm for ${alarm.hour}:${alarm.minute}');
      
      // Make sure the scheduled date is in the correct timezone
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('🔔 Timezone adjusted date: ${tzScheduledDate.toString()}');
      
      // Get notification ID
      final int notificationId = alarm.hashCode;
      
      // Schedule the notification (as backup/UI indicator)
      await _notifications.zonedSchedule(
        notificationId,
        alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        'Wake up!',
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm Notifications',
            channelDescription: 'Channel for alarm notifications',
            importance: Importance.max, 
            priority: Priority.high,
            playSound: false, // Silent notification (native alarm handles sound)
            sound: null,
            enableVibration: false,
          ),
        ),
        payload: alarm.id,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      debugPrint('✅ NOTIFICATION ALARM: Successfully scheduled notification alarm');
    } catch (e) {
      debugPrint('❌ NOTIFICATION ALARM: Error scheduling notification alarm: $e');
    }
  }
  
  // ✅ CANCEL NATIVE ALARM
  static Future<void> cancelNativeAlarm(String alarmId) async {
    try {
      debugPrint('🗑️ NATIVE ALARM: Cancelling native alarm $alarmId');
      
      final result = await _platformChannel.invokeMethod('cancelNativeAlarm', {
        'alarmId': alarmId,
      });
      
      if (result == true) {
        debugPrint('✅ NATIVE ALARM: Successfully cancelled native alarm');
      } else {
        debugPrint('❌ NATIVE ALARM: Failed to cancel native alarm');
      }
    } catch (e) {
      debugPrint('❌ NATIVE ALARM: Error cancelling native alarm: $e');
    }
  }
  
  // ✅ CANCEL ALL NATIVE ALARMS
  static Future<void> cancelAllNativeAlarms() async {
    try {
      debugPrint('🗑️ NATIVE ALARM: Cancelling all native alarms');
      
      final result = await _platformChannel.invokeMethod('cancelAllNativeAlarms');
      
      if (result == true) {
        debugPrint('✅ NATIVE ALARM: Successfully cancelled all native alarms');
        } else {
        debugPrint('❌ NATIVE ALARM: Failed to cancel all native alarms');
      }
    } catch (e) {
      debugPrint('❌ NATIVE ALARM: Error cancelling all native alarms: $e');
    }
  }
  
  // ✅ CANCEL ALARM METHOD - BOTH NOTIFICATION AND NATIVE NOTIFICATION
  static Future<void> cancelAlarm(String alarmId) async {
    try {
      debugPrint('🗑️ CANCELLING ALARM: Starting cancellation for $alarmId');
      
      // Cancel native notification
      await cancelNativeAlarm(alarmId);
      
      // Cancel notification alarm
      final alarm = HiveDatabase.getAlarm(alarmId);
      if (alarm != null) {
      final int notificationId = alarm.hashCode;
      await _notifications.cancel(notificationId);
        debugPrint('🗑️ Cancelled notification alarm with ID: $notificationId');
      }
      
      // Check if there are any remaining enabled alarms
      final allAlarms = HiveDatabase.getAllAlarms();
      final hasEnabledAlarms = allAlarms.any((a) => a.id != alarmId && a.isEnabled);
      
      // Update the pending alarms flag
      await _updatePendingAlarmsFlag(hasEnabledAlarms);
      
      debugPrint('✅ ALARM CANCELLED: Successfully cancelled both notification and native notification $alarmId');
    } catch (e) {
      debugPrint('❌ ERROR CANCELLING ALARM: $e');
    }
  }
  
  static Future<void> cancelAllAlarms() async {
    try {
      debugPrint('🗑️ CANCELLING ALL ALARMS: Starting...');
      
      // Cancel all native alarms
      await cancelAllNativeAlarms();
      
      // Cancel all notification alarms
      final alarms = HiveDatabase.getAllAlarms();
      for (final alarm in alarms) {
        final int notificationId = alarm.hashCode;
        await _notifications.cancel(notificationId);
      }
      
      // Update the pending alarms flag to false since all alarms are cancelled
      await _updatePendingAlarmsFlag(false);
      
      debugPrint('✅ ALL ALARMS CANCELLED: Successfully cancelled all alarms');
    } catch (e) {
      debugPrint('❌ ERROR CANCELLING ALL ALARMS: $e');
    }
  }

  // Request necessary permissions for alarms and notifications
  static Future<void> requestPermissions() async {
    debugPrint('Requesting alarm permissions...');
    // No need to do anything here since permissions are now handled by PermissionsManager
    // Keep this method for backward compatibility
  }

  // ✅ CHECK NATIVE ALARM PERMISSIONS
  static Future<bool> hasNativeAlarmPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Check SCHEDULE_EXACT_ALARM permission (Android 12+)
        if (await Permission.scheduleExactAlarm.isGranted) {
          debugPrint('✅ NATIVE ALARM: SCHEDULE_EXACT_ALARM permission granted');
          return true;
        } else {
          debugPrint('❌ NATIVE ALARM: SCHEDULE_EXACT_ALARM permission not granted');
          return false;
        }
      }
      return true; // iOS doesn't need this permission
    } catch (e) {
      debugPrint('❌ NATIVE ALARM: Error checking permissions: $e');
      return false;
    }
  }
  
  // ✅ REQUEST NATIVE ALARM PERMISSIONS
  static Future<bool> requestNativeAlarmPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request SCHEDULE_EXACT_ALARM permission
        final status = await Permission.scheduleExactAlarm.request();
        if (status.isGranted) {
          debugPrint('✅ NATIVE ALARM: SCHEDULE_EXACT_ALARM permission granted');
      return true;
        } else {
          debugPrint('❌ NATIVE ALARM: SCHEDULE_EXACT_ALARM permission denied');
      return false;
    }
  }
      return true; // iOS doesn't need this permission
    } catch (e) {
      debugPrint('❌ NATIVE ALARM: Error requesting permissions: $e');
      return false;
    }
  }
  
  // For directly checking notification settings
  static Future<Map<String, dynamic>> checkNotificationSettings() async {
    final Map<String, dynamic> settings = {};
    
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
        if (androidImplementation != null) {
          // Check if notifications are enabled
          final bool? areNotificationsEnabled = await androidImplementation.areNotificationsEnabled();
          settings['notifications_enabled'] = areNotificationsEnabled ?? false;
        }
        
        // Check exact alarm permission
        settings['exact_alarm'] = await Permission.scheduleExactAlarm.status;
        
        // Check battery optimization
        settings['battery_optimization'] = await Permission.ignoreBatteryOptimizations.status;
        
        // Check display over other apps
        settings['display_over_apps'] = await Permission.systemAlertWindow.status;
      }
      
      return settings;
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
      return settings;
    }
  }

  // Send alarm broadcast to native side
  static Future<void> _sendAlarmBroadcast(AlarmModel alarm) async {
    try {
      debugPrint('📱 ALARM BROADCAST: Sending broadcast for alarm ${alarm.id}');
    
    String soundName = 'alarm_sound'; // Default
    if (alarm.soundPath.isNotEmpty) {
      try {
        soundName = p.basenameWithoutExtension(alarm.soundPath); 
      } catch (e) {
          debugPrint('Error extracting sound name for broadcast: $e. Using default.');
        }
      }
      
      await _platformChannel.invokeMethod('sendAlarmBroadcast', {
        'id': alarm.id,
        'label': alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        'soundName': soundName,
        'hour': alarm.hour,
        'minute': alarm.minute,
      });
      
      debugPrint('📱 ALARM BROADCAST: Broadcast sent successfully');
    } catch (e) {
      debugPrint('❌ ALARM BROADCAST: Error sending broadcast: $e');
    }
  }

  // Fix release mode permissions
  static Future<void> fixReleasePermissions() async {
    try {
      debugPrint('🔧 RELEASE MODE: Fixing permissions...');
      
      // Request critical permissions for release mode
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      await Permission.ignoreBatteryOptimizations.request();
      
      debugPrint('✅ RELEASE MODE: Permissions fixed');
    } catch (e) {
      debugPrint('❌ RELEASE MODE: Error fixing permissions: $e');
    }
  }

  // Check if app can schedule alarms
  static Future<bool> canScheduleAlarms() async {
    try {
      if (Platform.isAndroid) {
        // Check if we have the necessary permissions
        final hasNotificationPermission = await Permission.notification.isGranted;
        final hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
        
        return hasNotificationPermission && hasExactAlarmPermission;
      }
      return true; // iOS doesn't need these specific permissions
    } catch (e) {
      debugPrint('Error checking alarm scheduling capability: $e');
      return false;
    }
  }

  // Test alarm functionality
  static Future<bool> testAlarmFocus() async {
    try {
      debugPrint('🧪 ALARM FOCUS TEST: Starting test...');
      
      // Create a test alarm
      final testAlarm = AlarmModel(
        id: 'test_alarm_${DateTime.now().millisecondsSinceEpoch}',
        hour: DateTime.now().hour,
        minute: DateTime.now().minute + 1, // 1 minute from now
        label: 'Test Alarm',
        soundPath: 'alarm_sound',
        isEnabled: true,
        vibrate: true,
        repeat: AlarmRepeat.once,
        weekdays: [false, false, false, false, false, false, false],
      );
      
      // Schedule the test alarm
      await scheduleAlarm(testAlarm);
      
      debugPrint('✅ ALARM FOCUS TEST: Test alarm scheduled');
      return true;
    } catch (e) {
      debugPrint('❌ ALARM FOCUS TEST ERROR: $e');
      return false;
    }
  }

  // Check all permissions for release builds
  static Future<Map<String, dynamic>> checkReleasePermissions() async {
    try {
      debugPrint('📱 ALARM SERVICE: Checking permissions for release build');
      
      final Map<String, dynamic> permissions = {};
      
      if (Platform.isAndroid) {
        permissions['notifications'] = await Permission.notification.status;
        permissions['exact_alarm'] = await Permission.scheduleExactAlarm.status;
        permissions['battery_optimization'] = await Permission.ignoreBatteryOptimizations.status;
        permissions['display_over_apps'] = await Permission.systemAlertWindow.status;
      }
      
      debugPrint('📱 ALARM SERVICE: Permission check complete: $permissions');
      return permissions;
    } catch (e) {
      debugPrint('❌ ALARM SERVICE: Error checking permissions: $e');
      return {};
    }
  }
  
  // Navigate to congratulations screen if ready
  static void tryNavigateToCongratulationsIfReady() {
    // This method is kept for compatibility but does nothing
    // The congratulations navigation is now handled elsewhere
    debugPrint('📱 ALARM SERVICE: tryNavigateToCongratulationsIfReady called (no-op)');
  }

  // Skip next alarm occurrence
  static Future<void> skipNextAlarm(AlarmModel alarm) async {
    try {
      debugPrint('⏭️ SKIP ALARM: Skipping next occurrence for ${alarm.hour}:${alarm.minute}');
      
      // Cancel current alarm
      await cancelAlarm(alarm.id);
      
      // For one-time alarms, just disable them
      if (alarm.repeat == AlarmRepeat.once) {
        final disabledAlarm = alarm.copyWith(isEnabled: false);
        await HiveDatabase.saveAlarm(disabledAlarm);
        debugPrint('⏭️ SKIP ALARM: One-time alarm disabled');
        return;
      }
      
      // For recurring alarms, reschedule for next occurrence
      await scheduleAlarm(alarm);
      debugPrint('⏭️ SKIP ALARM: Recurring alarm rescheduled for next occurrence');
    } catch (e) {
      debugPrint('❌ SKIP ALARM: Error skipping alarm: $e');
    }
  }
} 