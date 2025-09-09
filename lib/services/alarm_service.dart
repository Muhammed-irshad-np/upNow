import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // Import for Platform Channel
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
// import 'package:upnow/screens/alarm/alarm_ring_screen.dart';
import 'package:upnow/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
// import 'package:upnow/providers/alarm_provider.dart';

// Define a global variable to hold the current app lifecycle state
AppLifecycleState currentAppState = AppLifecycleState.resumed;

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  // Queue navigation to congratulations if native triggers it before Flutter UI is ready
  static bool _pendingCongratulationsNavigation = false;
  
  // Public helper for UI to attempt consuming pending navigation once navigator is available
  static void tryNavigateToCongratulationsIfReady() {
    try {
      if (!_pendingCongratulationsNavigation) return;
      final navigatorState = navigatorKey.currentState;
      if (navigatorState == null) return;
      navigatorState.pushNamedAndRemoveUntil(
        '/congratulations',
        (route) => false,
      );
      _pendingCongratulationsNavigation = false;
      debugPrint('📱 ALARM SERVICE: Consumed pending congratulations navigation');
    } catch (e) {
      debugPrint('📱 ALARM SERVICE: Error consuming pending navigation: $e');
    }
  }
  
  // Define the platform channel
  static const MethodChannel _platformChannel = 
      MethodChannel('com.example.upnow/alarm_overlay');
  
  // Method to show the overlay via platform channel
  static Future<void> _showOverlay(AlarmModel alarm) async {
    try {
      debugPrint('📱 ALARM OVERLAY: Requesting to show overlay for alarm ID ${alarm.id}');
      await _platformChannel.invokeMethod('showOverlay', {
        'id': alarm.id,
        'label': alarm.label.isNotEmpty ? alarm.label : 'Alarm', 
        'hour': alarm.hour, // Pass hour for time validation
        'minute': alarm.minute, // Pass minute for time validation
        // Add other necessary data for the overlay task here if needed
      });
      debugPrint('📱 ALARM OVERLAY: showOverlay method invoked.');
    } on PlatformException catch (e) {
      debugPrint("📱 ALARM OVERLAY: Failed to invoke showOverlay: '${e.message}'.");
    } catch (e) {
       debugPrint("📱 ALARM OVERLAY: Generic error invoking showOverlay: $e");
    }
  }

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
    
    // Create notification channels with high importance
    List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Notifications',
        description: 'Channel for alarm notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        enableLights: true,
      ),
      const AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'Channel for test notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        playSound: true,
        enableLights: true,
      ),
      const AndroidNotificationChannel(
        'alarm_focus',
        'Alarm Focus',
        description: 'High priority alarm notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'simple_channel',
        'Simple Test',
        description: 'Channel for ultra-simple notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        'immediate_channel',
        'Immediate Test',
        description: 'Channel for immediate test notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        playSound: true,
        enableLights: true,
      ),
    ];
    
    // Register all channels with the system
    final AndroidFlutterLocalNotificationsPlugin? androidNotifications =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidNotifications != null) {
      debugPrint('ALARM SERVICE: Creating ${channels.length} notification channels...');
      
      for (final channel in channels) {
        try {
          await androidNotifications.createNotificationChannel(channel);
          debugPrint('ALARM SERVICE: Created channel ${channel.id}');
        } catch (e) {
          debugPrint('ALARM SERVICE: Error creating channel ${channel.id}: $e');
        }
      }
    }
    
    // Initialize notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentSound: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationActionCallback,
    );
    
    _isInitialized = true;
    
    // Schedule all saved alarms
    await _scheduleAllAlarms();
    
    debugPrint('ALARM SERVICE: Alarm service initialized successfully');
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final alarmId = response.payload!;
      
      // If it's a backup notification, extract the actual alarm ID
      final String actualId = alarmId.startsWith('backup_') 
          ? alarmId.substring(7) // Remove 'backup_' prefix
          : alarmId;
      
      // Use the same handler as the background notifications
      _handleAlarmNotificationAction(actualId);
    }
  }
  
  // Method channel handler for native calls to Flutter
  static Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('📱 ALARM SERVICE: Received method call from native: ${call.method}');
    
    switch (call.method) {
      case 'openCongratulationsScreen':
        // Mark pending and try to navigate now if possible
        _pendingCongratulationsNavigation = true;
        tryNavigateToCongratulationsIfReady();
        debugPrint('📱 ALARM SERVICE: Received request to open congratulations (queued if navigator not ready)');
        break;
      default:
        debugPrint('📱 ALARM SERVICE: Unknown method call: ${call.method}');
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
  
  static Future<void> _scheduleAllAlarms() async {
    final alarms = HiveDatabase.getAllAlarms();
    debugPrint('Scheduling ${alarms.length} alarms');
    
    // Update the flag to indicate we have pending alarms
    await _updatePendingAlarmsFlag(alarms.any((alarm) => alarm.isEnabled));
    
    for (final alarm in alarms) {
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
      
      // Calculate the initial scheduled date based on the alarm's hour and minute
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );
      debugPrint('🔔 Initial scheduled date: ${scheduledDate.toString()}');
      
      // Adjust the scheduled date if it's in the past
      if (scheduledDate.isBefore(now)) {
        debugPrint('🔔 Scheduled date is in the past, adjusting...');
        
        // For "once" alarms, schedule for the next day
        if (alarm.repeat == AlarmRepeat.once) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
          debugPrint('🔔 Once alarm adjusted to tomorrow: ${scheduledDate.toString()}');
        }
        // For daily alarms, schedule for tomorrow
        else if (alarm.repeat == AlarmRepeat.daily) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
          debugPrint('🔔 Daily alarm adjusted to tomorrow: ${scheduledDate.toString()}');
        }
        // For weekday alarms, find the next weekday
        else if (alarm.repeat == AlarmRepeat.weekdays) {
          do {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          } while (scheduledDate.weekday > 5); // Skip Saturday (6) and Sunday (7)
          debugPrint('🔔 Weekday alarm adjusted to next weekday: ${scheduledDate.toString()} (Day ${scheduledDate.weekday})');
        }
        // For weekend alarms, find the next weekend day
        else if (alarm.repeat == AlarmRepeat.weekends) {
          do {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          } while (scheduledDate.weekday != 6 && scheduledDate.weekday != 7); // Only Saturday (6) and Sunday (7)
          debugPrint('🔔 Weekend alarm adjusted to next weekend: ${scheduledDate.toString()} (Day ${scheduledDate.weekday})');
        }
        // For custom repeat, find the next enabled day
        else if (alarm.repeat == AlarmRepeat.custom && alarm.weekdays.any((day) => day)) {
          debugPrint('🔔 Custom repeat pattern: ${alarm.weekdays}');
          int daysToAdd = 1;
          int checkDay = 0;
          bool foundNextDay = false;
          
          // Try up to 7 days to find the next enabled day
          while (checkDay < 7 && !foundNextDay) {
            final DateTime nextDay = scheduledDate.add(Duration(days: daysToAdd));
            // Convert weekday to index (0-6, where 0 is Monday in the weekdays array)
            final int weekdayIndex = (nextDay.weekday - 1) % 7;
            
            debugPrint('🔔 Checking day ${nextDay.toString()} (weekday ${nextDay.weekday}, index $weekdayIndex): ${alarm.weekdays[weekdayIndex]}');
            
            if (alarm.weekdays[weekdayIndex]) {
              scheduledDate = nextDay;
              foundNextDay = true;
              debugPrint('🔔 Found next custom day: ${scheduledDate.toString()} (Day ${scheduledDate.weekday})');
              break;
            }
            
            daysToAdd++;
            checkDay++;
          }
          
          if (!foundNextDay) {
            debugPrint('⚠️ No enabled days found for custom repeat, defaulting to tomorrow');
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
        } else {
          // Fallback - just add a day if nothing else matches
          debugPrint('⚠️ Unknown repeat pattern, defaulting to tomorrow');
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else {
        debugPrint('🔔 Scheduled date is in the future, keeping as is');
      }
      
      debugPrint('🔔 Final scheduled date: ${scheduledDate.toString()}');
      
      // Make sure the scheduled date is in the correct timezone
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('🔔 Timezone adjusted date: ${tzScheduledDate.toString()}');
      
      // --- Foreground Check ---
      final Duration timeUntilAlarm = tzScheduledDate.difference(tzNow);
      debugPrint('🔔 Time until alarm: $timeUntilAlarm');
      
      // Check if the alarm is very soon (e.g., within 5 seconds) AND app is in foreground
      const Duration foregroundThreshold = Duration(seconds: 5); 
      
      if (currentAppState == AppLifecycleState.resumed && 
          timeUntilAlarm > Duration.zero && // Ensure it's in the future
          timeUntilAlarm <= foregroundThreshold) {
            
        debugPrint('📱 App is in foreground and alarm is imminent. Triggering alarm broadcast.');
        
        // Cancel potentially existing notification for this specific time 
        final int notificationId = alarm.hashCode;
        await _notifications.cancel(notificationId);
        
        // Show the alarm via broadcast to receiver
        await _sendAlarmBroadcast(alarm);
        
        // We need to schedule the next occurrence for recurring alarms
        if (alarm.repeat != AlarmRepeat.once) {
          debugPrint('🔄 Need to schedule next occurrence for recurring alarm');
          await _rescheduleAlarmForNextOccurrence(alarm);
        }
        
        return; // Stop further processing for this specific alarm time
      }
      // --- End Foreground Check ---
      
      // Cancel any existing alarms with this ID (based on hash) to avoid duplicates
      final int alarmHashCode = alarm.hashCode;
      await _notifications.cancel(alarmHashCode);
      debugPrint('🔔 Cancelled any existing alarms with ID: $alarmHashCode');
      
      // Generate a unique notification ID based on the alarm hash and current time
      final int notificationId = alarmHashCode;
      debugPrint('🔔 Generated notification ID: $notificationId');

      // --- Dynamic Notification Details ---
      String soundName = 'alarm_sound'; // Default sound
      if (alarm.soundPath.isNotEmpty) {
         try {
           // Extract filename without extension
           soundName = p.basenameWithoutExtension(alarm.soundPath); 
         } catch (e) {
           debugPrint('Error extracting sound name: $e. Using default.');
           // Keep the default 'alarm_sound'
         }
      }
      debugPrint('🎵 Selected sound for notification: $soundName');
      
      // --- REMOVED Future.delayed timer here which doesn't work in terminated state ---
      // Instead rely on system notifications with proper intent configuration
      
      // Get the AndroidFlutterLocalNotificationsPlugin to set custom intents
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      // Create custom notification details with full screen intent
      AndroidNotificationDetails? enhancedAndroidDetails;
      
      if (androidImplementation != null) {
        try {
          // Create AndroidNotificationDetails with custom intents
          enhancedAndroidDetails = AndroidNotificationDetails(
            'alarm_channel',
            'Alarm Notifications',
            channelDescription: 'Channel for alarm notifications',
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound(soundName),
            playSound: true,
            enableVibration: alarm.vibrate,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false, // Changed to false to keep alarm notification visible
            additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
            ongoing: true,
            actions: [
              const AndroidNotificationAction(
                'show_alarm',
                'Show Alarm',
                showsUserInterface: true,
                cancelNotification: false,
              ),
            ],
          );
          
          // The broadcast action to launch our AlarmReceiver for automatic fullscreen
          await androidImplementation.createNotificationChannel(
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
          );
          
          // Add intent to directly launch the full alarm activity
          // This is critical for terminated state functionality
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'alarm_focus',
              'Alarm Focus', 
              description: 'High priority alarm notifications',
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound('alarm_sound'),
              enableVibration: true,
              playSound: true,
            ),
          );
          
          // Configure alarm intent
          final alarmIntent = {
            'id': alarm.id,
            'label': alarm.label.isNotEmpty ? alarm.label : 'Alarm',
            'soundName': soundName,
            'hour': alarm.hour,
            'minute': alarm.minute,
          };
          
          // Register the alarm with the platform for terminated state
          await _platformChannel.invokeMethod('registerTerminatedStateAlarm', alarmIntent);
          
          debugPrint('🔔 Enhanced notification details created successfully');
        } catch (e) {
          debugPrint('❌ Error creating enhanced notification details: $e');
        }
      }
      
      // Use enhanced details if available, otherwise fall back to basic details
      final AndroidNotificationDetails androidDetails = enhancedAndroidDetails ?? AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        autoCancel: true,
        additionalFlags: Int32List.fromList(<int>[4]),
        ongoing: true,
        actions: [
          AndroidNotificationAction(
            'show_alarm',
            'Show Alarm',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );
      
      // Default iOS settings
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true, // Use default iOS sound
      );

      // final NotificationDetails notificationDetails = NotificationDetails(
      //   android: androidDetails,
      //   iOS: iosDetails,
      // );
      
      // Schedule the simple "Wake up!" notification - This is *only* for display
      await _notifications.zonedSchedule(
        notificationId, // Use the consistent ID
        alarm.label.isNotEmpty ? alarm.label : 'Alarm', // Title
        'Wake up!', // Simplified Body
        tzScheduledDate, // Scheduled time
        // Modify details for silent informational notification
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel', // Use the same channel ID
            'Alarm Notifications',
            channelDescription: 'Channel for alarm notifications',
            importance: Importance.max, 
            priority: Priority.high,
            playSound: false, // *** Make this notification silent ***
            sound: null,      // *** Remove specific sound ***
            enableVibration: false, // No vibration needed here either
          ),
          // Keep basic iOS settings if needed, also silent
          iOS: DarwinNotificationDetails(
            presentSound: false,
          )
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Use precise scheduling
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(alarm.repeat), // Enable recurring notifications
        payload: alarm.id, // Keep payload just in case
      );

      debugPrint('🔔 Informational Notification scheduled for $tzScheduledDate with ID $notificationId');
      debugPrint('🔁 Repeat type: ${alarm.repeat} - Will auto-repeat: ${_getDateTimeComponents(alarm.repeat) != null}');

      // After scheduling, update the pending alarms flag
      final allAlarms = HiveDatabase.getAllAlarms();
      final hasEnabledAlarms = allAlarms.any((a) => a.isEnabled);
      await _updatePendingAlarmsFlag(hasEnabledAlarms);

    } catch (e) {
      debugPrint('❌ Error scheduling alarm ID ${alarm.id}: $e');
      // Consider re-throwing or showing an error to the user
    }
  }
  
  // This is called when a notification action is tapped in the background
  @pragma('vm:entry-point')
  static void notificationActionCallback(NotificationResponse response) {
    // This gets called in the background isolate and needs to be a top-level or static function
    debugPrint('Background notification response: ${response.id} - ${response.actionId} - ${response.payload}');
    
    // For background handling, we can only log and pass the info to the AlarmReceiver
    // The actual launching of the AlarmActivity happens in the native code
    if (response.payload != null && (response.actionId == 'show_alarm' || response.notificationResponseType == NotificationResponseType.selectedNotification)) {
      _handleAlarmNotificationAction(response.payload!);
    }
  }
  
  // Helper to send a broadcast to the native side to launch alarm activity
  static Future<void> _sendAlarmBroadcast(AlarmModel alarm) async {
    String soundName = 'alarm_sound'; // Default
    if (alarm.soundPath.isNotEmpty) {
      try {
        soundName = p.basenameWithoutExtension(alarm.soundPath); 
      } catch (e) {
        debugPrint('Error extracting sound name for broadcast: $e. Using default.');
      }
    }
    debugPrint('🎵 Using sound name for broadcast: $soundName');

    try {
      debugPrint('📱 ALARM BROADCAST: Sending broadcast for alarm ID ${alarm.id}');
      await _platformChannel.invokeMethod('sendAlarmBroadcast', {
        'id': alarm.id,
        'label': alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        'soundName': soundName, // Pass sound name
        'hour': alarm.hour, // Pass hour for time validation
        'minute': alarm.minute, // Pass minute for time validation
      });
      debugPrint('📱 ALARM BROADCAST: Broadcast sent');
    } on PlatformException catch (e) {
      debugPrint("📱 ALARM BROADCAST: Failed to send broadcast: '${e.message}'.");
    } catch (e) {
      debugPrint("📱 ALARM BROADCAST: Generic error sending broadcast: $e");
    }
  }

  // Helper to launch the alarm activity from both foreground and background
  static void _handleAlarmNotificationAction(String alarmId) {
    debugPrint('Handling alarm notification action for ID: $alarmId');
    
    // Get the alarm
    final alarm = HiveDatabase.getAlarm(alarmId);
    if (alarm != null) {
      // Use broadcast to launch native AlarmActivity
      _sendAlarmBroadcast(alarm);
      
      // Reschedule the alarm if it's a repeating alarm
      if (alarm.repeat != AlarmRepeat.once) {
        _rescheduleAlarmForNextOccurrence(alarm);
      }
    }
  }
  
  // Helper to reschedule alarm for next occurrence after it fires
  static Future<void> _rescheduleAlarmForNextOccurrence(AlarmModel alarm) async {
    try {
      debugPrint('🔄 Rescheduling alarm ID ${alarm.id} for next occurrence');
      
      // Only reschedule repeating alarms
      if (alarm.repeat == AlarmRepeat.once) {
        debugPrint('❌ Not rescheduling one-time alarm');
        
        // For one-time alarms, delete them after they fire
        await HiveDatabase.deleteAlarm(alarm.id);
        debugPrint('✅ One-time alarm deleted after firing');
        
        // No need to try to update UI directly - the app will refresh alarms when it becomes active
        
        return;
      }
      
      // Get current time
      final DateTime now = DateTime.now();
      
      // Start from today with the alarm time
      var nextOccurrence = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );
      
      debugPrint('🔄 Base date for calculation: ${nextOccurrence.toString()}');
      
      // Adjust for next occurrence based on repeat type
      if (alarm.repeat == AlarmRepeat.daily) {
        // For daily, add one day
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        debugPrint('🔄 Daily alarm - next occurrence: ${nextOccurrence.toString()}');
      } else if (alarm.repeat == AlarmRepeat.weekdays) {
        // Add one day first
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        
        // If we land on a weekend, jump to Monday
        if (nextOccurrence.weekday > 5) { // 6 = Saturday, 7 = Sunday
          // Calculate days until next Monday (weekday 1)
          int daysUntilMonday = 8 - nextOccurrence.weekday; // 8-6=2 (Sat->Mon), 8-7=1 (Sun->Mon)
          nextOccurrence = nextOccurrence.add(Duration(days: daysUntilMonday));
        }
        
        debugPrint('🔄 Weekday alarm - next occurrence: ${nextOccurrence.toString()} (Day ${nextOccurrence.weekday})');
      } else if (alarm.repeat == AlarmRepeat.weekends) {
        // Add one day first
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        
        // If we land on a weekday (1-5), jump to Saturday (6)
        if (nextOccurrence.weekday < 6) {
          // Calculate days until next Saturday (weekday 6)
          int daysUntilSaturday = 6 - nextOccurrence.weekday;
          nextOccurrence = nextOccurrence.add(Duration(days: daysUntilSaturday));
        }
        
        debugPrint('🔄 Weekend alarm - next occurrence: ${nextOccurrence.toString()} (Day ${nextOccurrence.weekday})');
      } else if (alarm.repeat == AlarmRepeat.custom && alarm.weekdays.any((day) => day)) {
        // First check if there are any days enabled
        if (!alarm.weekdays.contains(true)) {
          debugPrint('⚠️ Custom alarm has no days enabled, not rescheduling');
          return;
        }
        
        debugPrint('🔄 Custom repeat pattern: ${alarm.weekdays}');
        
        // Add one day first
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        int currentWeekdayIndex = (nextOccurrence.weekday - 1) % 7; // Convert to 0-6 index
        
        // If current day is not enabled, find the next enabled day
        if (!alarm.weekdays[currentWeekdayIndex]) {
          bool foundDay = false;
          
          // Try each day, up to 7 days
          for (int i = 1; i <= 7; i++) {
            final checkDate = nextOccurrence.add(Duration(days: i - 1));
            final weekdayIndex = (checkDate.weekday - 1) % 7;
            
            debugPrint('🔄 Checking day ${checkDate.toString()} (weekday ${checkDate.weekday}, index $weekdayIndex): ${alarm.weekdays[weekdayIndex]}');
            
            if (alarm.weekdays[weekdayIndex]) {
              nextOccurrence = checkDate;
              foundDay = true;
              debugPrint('🔄 Found next custom day: ${nextOccurrence.toString()} (Day ${nextOccurrence.weekday})');
              break;
            }
          }
          
          if (!foundDay) {
            debugPrint('⚠️ Could not find next enabled day for custom alarm, not rescheduling');
            return;
          }
        } else {
          debugPrint('🔄 Next day is already enabled: ${nextOccurrence.toString()} (Day ${nextOccurrence.weekday})');
        }
      }
      
      debugPrint('🔄 Final next occurrence: ${nextOccurrence.toString()}');
      
      // Update the alarm with the next occurrence time (keeping the hour/minute the same)
      // We don't need to modify the alarm object since the hour/minute stay the same
      // Just reschedule it
      
      // Use the existing alarm scheduling mechanism
      await scheduleAlarm(alarm);
      
    } catch (e) {
      debugPrint('❌ Error rescheduling alarm: $e');
    }
  }
  
  // Add a new method to handle battery optimization
  static Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      try {
        // Use permission_handler for battery optimization
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          final status = await Permission.ignoreBatteryOptimizations.request();
          debugPrint('Battery optimization exemption status: $status');
        }
      } catch (e) {
        debugPrint('Error requesting battery optimization exemption: $e');
      }
    }
  }
  
  static DateTimeComponents? _getDateTimeComponents(AlarmRepeat repeat) {
    switch (repeat) {
      case AlarmRepeat.once:
        return null;
      case AlarmRepeat.daily:
        return DateTimeComponents.time;
      case AlarmRepeat.weekdays:
      case AlarmRepeat.weekends:
      case AlarmRepeat.custom:
        return DateTimeComponents.dayOfWeekAndTime;
    }
  }
  
  static Future<void> cancelAlarm(String alarmId) async {
    try {
      debugPrint('Cancelling alarm with ID: $alarmId');
      
      // Get the alarm from database
      final alarm = HiveDatabase.getAlarm(alarmId);
      if (alarm == null) {
        debugPrint('Alarm not found with ID: $alarmId');
        return;
      }
      
      // Cancel the notification
      final int notificationId = alarm.hashCode;
      await _notifications.cancel(notificationId);
      
      // Check if there are any remaining enabled alarms
      final allAlarms = HiveDatabase.getAllAlarms();
      final hasEnabledAlarms = allAlarms.any((a) => a != null && a.id != alarmId && a.isEnabled);
      
      // Update the pending alarms flag
      await _updatePendingAlarmsFlag(hasEnabledAlarms);
      
      debugPrint('Alarm cancelled with ID: $alarmId');
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
    }
  }
  
  static Future<void> cancelAllAlarms() async {
    try {
      debugPrint('Cancelling all alarms');
      
      // Get all alarms
      final alarms = HiveDatabase.getAllAlarms();
      
      // Cancel each alarm notification
      for (final alarm in alarms) {
        final int notificationId = alarm.hashCode;
        await _notifications.cancel(notificationId);
      }
      
      // Update the pending alarms flag to false since all alarms are cancelled
      await _updatePendingAlarmsFlag(false);
      
      debugPrint('All alarms cancelled');
    } catch (e) {
      debugPrint('Error cancelling all alarms: $e');
    }
  }

  // Request necessary permissions for alarms and notifications
  static Future<void> requestPermissions() async {
    debugPrint('Requesting alarm permissions...');
    // No need to do anything here since permissions are now handled by PermissionsManager
    // Keep this method for backward compatibility
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
          settings['notifications_enabled'] = areNotificationsEnabled;
        }
        
        // Check exact alarm permission
        settings['exact_alarm'] = await Permission.scheduleExactAlarm.status;
        
        // Check battery optimization
        settings['battery_optimization'] = await Permission.ignoreBatteryOptimizations.status;
        
        // Get pending notifications count
        final pendingNotifications = await _notifications.pendingNotificationRequests();
        settings['pending_notifications'] = pendingNotifications.length;
      }
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
      settings['error'] = e.toString();
    }
    
    return settings;
  }

  // Direct test method for notifications
  static Future<bool> testDirectNotification() async {
    try {
      // Ensure initialized
      if (!_isInitialized) await init();
      
      // Create notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        channelDescription: 'Notifications for scheduled alarms',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm_sound.mp3',
        ),
      );
      
      // Get current time for payload
      final now = DateTime.now();
      final timestamp = '${now.hour}:${now.minute}:${now.second}';
      
      // Show notification directly
      await _notifications.show(
        99999,
        'DIRECT TEST',
        'Direct test notification sent at $timestamp',
        notificationDetails,
        payload: 'direct_test',
      );
      
      debugPrint('Direct test notification sent at $timestamp');
      return true;
    } catch (e) {
      debugPrint('Error sending direct test notification: $e');
      return false;
    }
  }

  // Ultra simple notification test
  static Future<bool> testSimpleNotification() async {
    try {
      final FlutterLocalNotificationsPlugin notifier = FlutterLocalNotificationsPlugin();
      
      // Create a super simple channel if not initialized
      if (!_isInitialized) {
        // Initialize with minimum settings
        const AndroidInitializationSettings androidSettings = 
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initSettings = 
            InitializationSettings(android: androidSettings);
        await notifier.initialize(initSettings);
        
        // Create a simple channel
        const AndroidNotificationChannel simpleChannel = AndroidNotificationChannel(
          'simple_channel', 
          'Simple Test',
          importance: Importance.max,
        );
        
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
            notifier.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(simpleChannel);
        }
      }
      
      // Super simple notification
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'simple_channel',
        'Simple Test',
        importance: Importance.max,
        priority: Priority.max,
      );
      
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      
      // Show basic notification
      final now = DateTime.now();
      await notifier.show(
        12345,
        'ULTRA SIMPLE TEST',
        'Simple test at ${now.hour}:${now.minute}:${now.second}',
        details,
      );
      
      debugPrint('SIMPLE TEST: Sent notification at ${now.toString()}');
      return true;
    } catch (e) {
      debugPrint('SIMPLE TEST ERROR: $e');
      return false;
    }
  }
  
  // Test notification with special alarm settings
  static Future<bool> testAlarmFocusedNotification() async {
    try {
      // Ensure initialized
      if (!_isInitialized) await init();
      
      // Use a dedicated alarm channel
      const AndroidNotificationChannel alarmFocusChannel = AndroidNotificationChannel(
        'alarm_focus',
        'Alarm Focus',
        description: 'High priority alarm notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );
      
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(alarmFocusChannel);
      }
      
      // Create notification with max priority
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_focus',
        'Alarm Focus',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ticker: 'ALARM',
        color: Color.fromARGB(255, 255, 0, 0),
        colorized: true,
        ongoing: true,
        autoCancel: false,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Current timestamp
      final now = DateTime.now();
      final timestamp = '${now.hour}:${now.minute}:${now.second}';
      
      // Show focused alarm
      await _notifications.show(
        88888,
        'ALARM TEST',
        'Special alarm configuration test at $timestamp',
        notificationDetails,
      );
      
      debugPrint('ALARM FOCUS TEST: Sent notification at $timestamp');
      return true;
    } catch (e) {
      debugPrint('ALARM FOCUS TEST ERROR: $e');
      return false;
    }
  }

  // When alarm time is reached, this method will be called to launch the fullscreen activity
  static Future<void> _launchFullscreenAlarm(String alarmId, String label) async {
    debugPrint('📱 ALARM LAUNCH: Attempting to show fullscreen alarm for $alarmId');
    // Retrieve alarm to get sound path
    final alarm = HiveDatabase.getAlarm(alarmId);
    if (alarm == null) {
      debugPrint('❌ Alarm not found with ID: $alarmId');
      return;
    }
    
    // Check if the alarm time has already passed (comparing only hour and minute)
    final now = DateTime.now();
    final bool isAlarmInPast = 
        (now.hour > alarm.hour) || 
        (now.hour == alarm.hour && now.minute > alarm.minute);
    
    if (isAlarmInPast) {
      debugPrint('⏰ Not showing alarm that has already passed: ${alarm.hour}:${alarm.minute}');
      return;
    }
    
    String soundName = 'alarm_sound'; // Default
    if (alarm.soundPath.isNotEmpty) {
      try {
        soundName = p.basenameWithoutExtension(alarm.soundPath); 
      } catch (e) {
        debugPrint('Error extracting sound name for launch: $e. Using default.');
      }
    }
    debugPrint('🎵 Using sound name for launch: $soundName');

    try {
      // First try direct method channel call to immediately show the math screen
      final result = await _platformChannel.invokeMethod('showOverlay', {
        'id': alarmId,
        'label': label,
        'soundName': soundName, // Pass sound name
        'hour': alarm.hour, // Pass hour
        'minute': alarm.minute, // Pass minute
      });
      debugPrint('📱 ALARM LAUNCH: Direct launch result: $result');
      
      // Also send broadcast as backup method (belt and suspenders approach)
      await _sendAlarmBroadcast(alarm); // Pass the full alarm model
      debugPrint('📱 ALARM BROADCAST: Backup broadcast sent');
    } catch (e) {
      debugPrint('❌ ERROR launching fullscreen alarm: $e');
    }
  }

  // Check all permissions for release builds
  static Future<Map<String, dynamic>> checkReleasePermissions() async {
    try {
      debugPrint('📱 ALARM SERVICE: Checking permissions for release build');
      
      // Check native permissions through platform channel
      final Map<String, dynamic> nativePermissions = 
          await _platformChannel.invokeMethod('checkAlarmPermissions')
              .then((result) => Map<String, dynamic>.from(result as Map))
              .catchError((e) {
                debugPrint('Error checking native permissions: $e');
                return <String, dynamic>{'error': e.toString()};
              });
      
      // Check Flutter permissions using permission_handler
      final Map<String, dynamic> flutterPermissions = {};
      
      // Schedule exact alarms permission
      flutterPermissions['scheduleExactAlarm'] = 
          await Permission.scheduleExactAlarm.status.isGranted;
      
      // Notification permission
      flutterPermissions['notification'] = 
          await Permission.notification.status.isGranted;
      
      // Battery optimization
      flutterPermissions['ignoreBatteryOptimizations'] = 
          await Permission.ignoreBatteryOptimizations.status.isGranted;
          
      // System alert window permission (overlay)
      flutterPermissions['systemAlertWindow'] = 
          await Permission.systemAlertWindow.status.isGranted;
      
      // Get the number of scheduled alarms
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      
      // Combine all results
      return {
        'native': nativePermissions,
        'flutter': flutterPermissions,
        'pendingNotificationsCount': pendingNotifications.length,
        'appLifecycleState': currentAppState.toString(),
      };
    } catch (e) {
      debugPrint('Error in checkReleasePermissions: $e');
      return {'error': e.toString()};
    }
  }
  
  // Fix permissions for release builds
  static Future<bool> fixReleasePermissions() async {
    try {
      debugPrint('📱 ALARM SERVICE: Checking permissions for release build');
      
      // Check all permissions but don't request them automatically
      // This ensures we're aware of the current permission state
      final permissionStatus = await checkReleasePermissions();
      debugPrint('📱 ALARM SERVICE: Current permission status: $permissionStatus');
      
      // Don't request permissions here anymore - let the PermissionsScreen handle it
      // This prevents prompting at startup on physical devices
      
      return true;
    } catch (e) {
      debugPrint('Error checking release permissions: $e');
      return false;
    }
  }

  // Test alarm functionality in release mode
  static Future<Map<String, dynamic>> testReleaseAlarm() async {
    try {
      debugPrint('📱 ALARM SERVICE: Testing alarm in release mode');
      
      // First check permissions
      final permissionStatus = await checkReleasePermissions();
      
      // Create a test alarm for 30 seconds from now
      final now = DateTime.now();
      final testAlarmTime = now.add(const Duration(seconds: 30));
      
      // Create a test alarm model
      final testAlarm = AlarmModel(
        id: 'test_release_${now.millisecondsSinceEpoch}',
        hour: testAlarmTime.hour,
        minute: testAlarmTime.minute,
        isEnabled: true,
        label: 'Release Test Alarm',
        vibrate: true,
        repeat: AlarmRepeat.once,
        weekdays: List.filled(7, false),
        soundPath: 'alarm_sound',
        dismissType: DismissType.normal,
      );
      
      // Log the test alarm
      debugPrint('📱 ALARM SERVICE: Created test alarm for ${testAlarmTime.toString()}');
      
      // Try to schedule it
      await scheduleAlarm(testAlarm);
      
      // Get pending notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      
      // Also send a direct test notification
      await testDirectNotification();
      
      // Log result and return status
      return {
        'permissionStatus': permissionStatus,
        'testAlarmCreated': true,
        'testAlarmTime': '${testAlarmTime.hour}:${testAlarmTime.minute}:${testAlarmTime.second}',
        'pendingNotificationsCount': pendingNotifications.length,
      };
    } catch (e) {
      debugPrint('Error testing release alarm: $e');
      return {'error': e.toString()};
    }
  }

  static Future<void> skipNextAlarm(AlarmModel alarm) async {
    // This is a placeholder.
    // The actual implementation will depend on how alarms are stored and scheduled
    // on the native side. It might involve:
    // 1. Finding the next scheduled alarm instance.
    // 2. Cancelling it.
    // 3. Scheduling the *following* alarm instance.
    // For now, we'll just log it.
    debugPrint("Skipping next occurrence of alarm: ${alarm.id}");

    // Example of what it might look like:
    // final nextTime = alarm.getNextAlarmTime(skip: 1); // Get time after next
    // await cancelAlarm(alarm.id);
    // alarm.reschedule(nextTime);
    // await scheduleAlarm(alarm);
  }
} 