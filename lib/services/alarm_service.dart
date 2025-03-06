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

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Check for notification permissions
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Request exact alarm permission (Android 12+)
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint('Error requesting exact alarms permission: $e');
        }
        
        // Request notification permission (Android 13+)
        try {
          await androidImplementation.requestNotificationsPermission();
        } catch (e) {
          debugPrint('Error requesting notification permission: $e');
        }
      }
    }
    
    // Create notification channel with high importance
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Notifications',
      description: 'Channel for alarm notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
      playSound: true,
      enableLights: true,
    );
    
    // Register the channel with the system
    final AndroidFlutterLocalNotificationsPlugin? androidNotifications =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidNotifications != null) {
      await androidNotifications.createNotificationChannel(channel);
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
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final alarmId = response.payload!;
      final alarm = HiveDatabase.getAlarm(alarmId);
      
      if (alarm != null) {
        // Use this to navigate to the alarm ring screen
        // We need a navigatorKey in the main app for this to work
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlarmRingScreen(alarm: alarm),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }
  
  static Future<void> _scheduleAllAlarms() async {
    final alarms = HiveDatabase.getAllAlarms();
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
  
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!_isInitialized) await init();
    
    // Cancel existing alarm with this ID
    await _notifications.cancel(alarm.id.hashCode);
    
    if (!alarm.isEnabled) return;
    
    // Calculate next alarm time
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );
    
    // If the alarm time is in the past, schedule for the next occurrence
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Adjust based on repeat pattern
    switch (alarm.repeat) {
      case AlarmRepeat.once:
        // No adjustment needed
        break;
      case AlarmRepeat.daily:
        // No adjustment needed, will repeat daily
        break;
      case AlarmRepeat.weekdays:
        // If it's weekend, move to Monday
        if (scheduledDate.weekday == DateTime.saturday) {
          scheduledDate = scheduledDate.add(const Duration(days: 2));
        } else if (scheduledDate.weekday == DateTime.sunday) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        break;
      case AlarmRepeat.weekends:
        // If it's weekday, move to Saturday
        if (scheduledDate.weekday >= DateTime.monday && scheduledDate.weekday <= DateTime.friday) {
          scheduledDate = scheduledDate.add(Duration(days: DateTime.saturday - scheduledDate.weekday));
        }
        break;
      case AlarmRepeat.custom:
        // Find the next day that is enabled
        int daysToAdd = 0;
        bool found = false;
        
        for (int i = 0; i < 7; i++) {
          // Convert weekday to index (0 = Monday, 6 = Sunday)
          int dayIndex = (scheduledDate.weekday - 1 + i) % 7;
          if (alarm.weekdays[dayIndex]) {
            daysToAdd = i;
            found = true;
            break;
          }
        }
        
        if (found) {
          scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
        } else {
          // No days selected, treat as once
          // No adjustment needed
        }
        break;
    }
    
    // Convert to TZDateTime
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // Schedule the notification
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Notifications for scheduled alarms',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm_sound.mp3',
      ),
    );
    
    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      alarm.label.isNotEmpty ? alarm.label : 'Alarm',
      'Tap to dismiss',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getDateTimeComponents(alarm.repeat),
      payload: alarm.id,
    );
    
    debugPrint('Scheduled alarm for ${tzScheduledDate.toString()} (ID: ${alarm.id})');
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
  }
  
  static Future<void> cancelAllAlarms() async {
    if (!_isInitialized) await init();
    await _notifications.cancelAll();
  }

  // Request necessary permissions for alarms and notifications
  Future<void> requestPermissions() async {
    // For notifications on Android 13+
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // For alarm scheduling on Android 14+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    // For notification permission using permission handler 
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    debugPrint('Requested all necessary permissions for alarms');
  }
} 