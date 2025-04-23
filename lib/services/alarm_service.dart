import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'package:upnow/screens/alarm/alarm_ring_screen.dart';
import 'package:upnow/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;


class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    debugPrint('ALARM SERVICE: Initializing alarm service...');
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Request permissions first
    await requestPermissions();
    
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
      
      final alarm = HiveDatabase.getAlarm(actualId);
      
      debugPrint('Retrieved alarm: $alarm');
      
      if (alarm != null) {
        // Use this to navigate to the alarm ring screen
        // We need a navigatorKey in the main app for this to work
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlarmRingScreen(alarm: alarm),
            fullscreenDialog: true,
          ),
        );
      } else {
        debugPrint('Error: Could not find alarm with ID: $actualId');
      }
    }
  }
  
  static Future<void> _scheduleAllAlarms() async {
    final alarms = HiveDatabase.getAllAlarms();
    debugPrint('Scheduling ${alarms.length} alarms');
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
      debugPrint('🔔 Current time: ${now.toString()}');
      
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
        }
        // For daily alarms, schedule for tomorrow
        else if (alarm.repeat == AlarmRepeat.daily) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        // For weekday alarms, find the next weekday
        else if (alarm.repeat == AlarmRepeat.weekdays) {
          do {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          } while (scheduledDate.weekday > 5); // Skip Saturday (6) and Sunday (7)
        }
        // For weekend alarms, find the next weekend day
        else if (alarm.repeat == AlarmRepeat.weekends) {
          do {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          } while (scheduledDate.weekday != 6 && scheduledDate.weekday != 7); // Only Saturday (6) and Sunday (7)
        }
        // For custom repeat, find the next enabled day
        else if (alarm.repeat == AlarmRepeat.custom && alarm.weekdays.any((day) => day)) {
          int daysToAdd = 1;
          int checkDay = 0;
          // Try up to 7 days to find the next enabled day
          while (checkDay < 7) {
            final DateTime nextDay = scheduledDate.add(Duration(days: daysToAdd));
            // Convert weekday to index (0-6, where 0 is Monday in the weekdays array)
            final int weekdayIndex = (nextDay.weekday - 1) % 7;
            if (alarm.weekdays[weekdayIndex]) {
              scheduledDate = nextDay;
              break;
            }
            daysToAdd++;
            checkDay++;
          }
        }
      }
      
      debugPrint('🔔 Final scheduled date: ${scheduledDate.toString()}');
      
      // Make sure the scheduled date is in the correct timezone
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('🔔 Timezone adjusted date: ${tzScheduledDate.toString()}');
      
      // Cancel any existing alarms with this ID (based on hash) to avoid duplicates
      final int alarmHashCode = alarm.hashCode;
      await _notifications.cancel(alarmHashCode);
      debugPrint('🔔 Cancelled any existing alarms with ID: $alarmHashCode');
      
      // Generate a unique notification ID based on the alarm hash and current time
      final int notificationId = alarmHashCode;
      debugPrint('🔔 Generated notification ID: $notificationId');

      // --- Dynamic Notification Details ---
      String soundName = 'alarm_sound'; // Default sound
      if (alarm.soundPath != null && alarm.soundPath!.isNotEmpty) {
         try {
           // Extract filename without extension
           soundName = p.basenameWithoutExtension(alarm.soundPath!); 
         } catch (e) {
           debugPrint('Error extracting sound name: $e. Using default.');
           // Keep the default 'alarm_sound'
         }
      }
      debugPrint('🔔 Using sound: $soundName');

      // Create AndroidNotificationDetails dynamically
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_channel', // Ensure this channel is created in init()
        'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(soundName), // Use extracted sound name
        playSound: true,
        enableVibration: alarm.vibrate, // Use vibrate setting from alarm model
        fullScreenIntent: true, 
        category: AndroidNotificationCategory.alarm,
        // ongoing: true, // Optional: keeps notification until dismissed
        // actions: [ ... ] // Optional: Add snooze/dismiss actions
      );
      
      // Default iOS settings (iOS sound customization might need platform channels or specific packages)
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true, // Use default iOS sound
        // sound: 'custom_sound.caf', // Example if you add sounds to iOS project
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      // --- End Dynamic Notification Details ---

      await _notifications.zonedSchedule(
        notificationId, // Use the consistent ID
        alarm.label.isNotEmpty ? alarm.label : 'Alarm', // Title
        'Time to wake up!', // Body
        tzScheduledDate, // Scheduled time
        notificationDetails, // Use the dynamically created details
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Use precise scheduling
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: alarm.repeat == AlarmRepeat.once 
                                   ? null // Don't repeat for 'once'
                                   : DateTimeComponents.time, // Repeat daily/weekly based on time
        payload: alarm.id, // Use the actual alarm ID string as payload
      );

      debugPrint('✅ ALARM SCHEDULED: ID $notificationId at $tzScheduledDate with sound $soundName');

      // Schedule backup notification if needed (existing logic)
      // ... (Consider if backup needs custom sound too)

    } catch (e) {
      debugPrint('❌ Error scheduling alarm ID ${alarm.id}: $e');
      // Consider re-throwing or showing an error to the user
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
  
  static Future<void> cancelAlarm(String id) async {
    if (!_isInitialized) await init();
    await _notifications.cancel(id.hashCode);
    debugPrint('Cancelled alarm with ID: $id');
  }
  
  static Future<void> cancelAllAlarms() async {
    if (!_isInitialized) await init();
    await _notifications.cancelAll();
    debugPrint('Cancelled all alarms');
  }

  // Request necessary permissions for alarms and notifications
  static Future<void> requestPermissions() async {
    debugPrint('Requesting alarm permissions...');
        await requestBatteryOptimizationExemption();

    // For notifications on Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Add this code to your requestPermissions method
// Request battery optimization exemption
try {
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    final status = await Permission.ignoreBatteryOptimizations.request();
    debugPrint('Battery optimization exemption status: $status');
  }
} catch (e) {
  debugPrint('Error requesting battery optimization exemption: $e');
}
      if (androidImplementation != null) {
        // Request exact alarm permission (Android 12+)
        try {
          final hasExactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
          debugPrint('Exact alarm permission: $hasExactAlarmPermission');
        } catch (e) {
          debugPrint('Error requesting exact alarms permission: $e');
        }
        
        // Request notification permission (Android 13+)
        try {
          final hasNotificationPermission = await androidImplementation.requestNotificationsPermission();
          debugPrint('Notification permission: $hasNotificationPermission');
        } catch (e) {
          debugPrint('Error requesting notification permission: $e');
        }
      }
    }
    
    // For alarm scheduling on Android 14+
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('Schedule exact alarm permission status: $status');
    }
    
    // For notification permission using permission handler 
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      debugPrint('Notification permission status: $status');
    }
    
    debugPrint('Finished requesting all necessary permissions for alarms');
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
} 