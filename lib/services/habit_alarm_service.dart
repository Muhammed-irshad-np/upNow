import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';

class HabitAlarmService {
  static const String _habitChannelId = 'habit_reminders';
  static const String _habitChannelName = 'Habit Reminders';
  static const String _habitChannelDescription = 'Notifications for habit reminders';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _habitChannelId,
      _habitChannelName,
      description: _habitChannelDescription,
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - you can navigate to habit screen
    if (response.payload != null) {
      debugPrint('Habit alarm tapped: ${response.payload}');
      // Navigate to habit detail or mark as completed
    }
  }

  // Schedule habit alarm
  static Future<void> scheduleHabitAlarm(HabitModel habit) async {
    if (!habit.hasAlarm || habit.targetTime == null) return;

    await cancelHabitAlarm(habit.id);

    final now = DateTime.now();
    final targetTime = habit.targetTime!;
    
    // Create the scheduled date for today
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      _getHabitNotificationId(habit.id),
      '${habit.name} Reminder',
      _getHabitNotificationBody(habit),
      scheduledTZDate,
      _getNotificationDetails(habit),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getDateTimeComponents(habit.frequency),
      payload: habit.id,
    );

    debugPrint('Scheduled habit alarm for ${habit.name} at $scheduledTZDate');
  }

  // Cancel habit alarm
  static Future<void> cancelHabitAlarm(String habitId) async {
    await _notificationsPlugin.cancel(_getHabitNotificationId(habitId));
    debugPrint('Cancelled habit alarm for $habitId');
  }

  // Schedule all habit alarms
  static Future<void> scheduleAllHabitAlarms(List<HabitModel> habits) async {
    for (final habit in habits) {
      if (habit.hasAlarm && habit.isActive && !habit.isArchived) {
        await scheduleHabitAlarm(habit);
      }
    }
  }

  // Cancel all habit alarms
  static Future<void> cancelAllHabitAlarms() async {
    await _notificationsPlugin.cancelAll();
  }

  // Get notification ID for habit
  static int _getHabitNotificationId(String habitId) {
    // Convert habit ID to integer for notification ID
    return habitId.hashCode.abs() % 2147483647; // Keep within int32 range
  }

  // Get notification details
  static NotificationDetails _getNotificationDetails(HabitModel habit) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _habitChannelId,
        _habitChannelName,
        channelDescription: _habitChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: habit.color,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          _getHabitNotificationBody(habit),
          contentTitle: '${habit.name} Reminder',
        ),
        actions: [
          AndroidNotificationAction(
            'mark_completed',
            'Mark Completed',
            titleColor: habit.color,
          ),
          AndroidNotificationAction(
            'snooze',
            'Snooze 15min',
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'habit_reminder',
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  // Get notification body
  static String _getHabitNotificationBody(HabitModel habit) {
    final time = habit.targetTime != null 
        ? '${habit.targetTime!.hour.toString().padLeft(2, '0')}:${habit.targetTime!.minute.toString().padLeft(2, '0')}'
        : 'now';
    
    String body = "Time to work on your habit!";
    
    if (habit.description != null && habit.description!.isNotEmpty) {
      body = habit.description!;
    }
    
    switch (habit.frequency) {
      case HabitFrequency.daily:
        body += " • Daily at $time";
        break;
      case HabitFrequency.weekly:
        body += " • Weekly reminder";
        break;
      case HabitFrequency.monthly:
        body += " • Monthly reminder";
        break;
      default:
        body += " • Custom reminder";
    }
    
    return body;
  }

  // Get date time components for scheduling
  static DateTimeComponents? _getDateTimeComponents(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return DateTimeComponents.time;
      case HabitFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case HabitFrequency.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return DateTimeComponents.time;
    }
  }

  // Show immediate habit reminder
  static Future<void> showHabitReminder(HabitModel habit, {String? customMessage}) async {
    await _notificationsPlugin.show(
      _getHabitNotificationId(habit.id),
      '${habit.name} Reminder',
      customMessage ?? _getHabitNotificationBody(habit),
      _getNotificationDetails(habit),
      payload: habit.id,
    );
  }

  // Snooze habit alarm
  static Future<void> snoozeHabitAlarm(String habitId, int minutes) async {
    await cancelHabitAlarm(habitId);
    
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozeTZTime = tz.TZDateTime.from(snoozeTime, tz.local);
    
    await _notificationsPlugin.zonedSchedule(
      _getHabitNotificationId(habitId),
      'Habit Reminder (Snoozed)',
      'Your habit reminder is back!',
      snoozeTZTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: habitId,
    );
  }

  // Get pending habit notifications
  static Future<List<PendingNotificationRequest>> getPendingHabitAlarms() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.where((notification) => 
      notification.id.toString().startsWith('habit_')).toList();
  }

  // Update habit alarms when habit changes
  static Future<void> updateHabitAlarms(HabitModel habit) async {
    if (habit.hasAlarm && habit.isActive && !habit.isArchived) {
      await scheduleHabitAlarm(habit);
    } else {
      await cancelHabitAlarm(habit.id);
    }
  }

  // Check if habit has pending alarm
  static Future<bool> hasHabitAlarm(String habitId) async {
    final pending = await getPendingHabitAlarms();
    return pending.any((notification) => 
      notification.payload == habitId);
  }

  // Send motivational notification
  static Future<void> sendMotivationalNotification(HabitModel habit, HabitStats stats) async {
    String message;
    
    if (stats.currentStreak == 0) {
      message = "Start your ${habit.name} streak today! 💪";
    } else if (stats.currentStreak < 7) {
      message = "Keep going! You're on a ${stats.currentStreak} day streak! 🔥";
    } else if (stats.currentStreak < 30) {
      message = "Amazing! ${stats.currentStreak} days strong! 🎉";
    } else {
      message = "Incredible! ${stats.currentStreak} days - you're unstoppable! 🏆";
    }

    await _notificationsPlugin.show(
      _getHabitNotificationId('${habit.id}_motivation'),
      'Habit Motivation',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: habit.color,
          styleInformation: BigTextStyleInformation(message),
        ),
      ),
      payload: habit.id,
    );
  }

  // Schedule weekly habit summary
  static Future<void> scheduleWeeklySummary() async {
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final summaryTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      19, // 7 PM
      0,
    );

    await _notificationsPlugin.zonedSchedule(
      999999, // Special ID for weekly summary
      'Weekly Habit Summary',
      'Check out your habit progress this week!',
      tz.TZDateTime.from(summaryTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }
}

// Extension to handle notification actions
extension HabitAlarmActions on HabitAlarmService {
  static Future<void> handleNotificationAction(
    String action,
    String habitId,
    HabitService habitService,
  ) async {
    switch (action) {
      case 'mark_completed':
        await habitService.markHabitCompleted(habitId, DateTime.now());
        await showHabitReminder(
          habitService.habits.firstWhere((h) => h.id == habitId),
          customMessage: 'Great job! Habit completed! 🎉',
        );
        break;
      case 'snooze':
        await snoozeHabitAlarm(habitId, 15);
        break;
    }
  }
}

// Habit alarm provider for state management
class HabitAlarmProvider extends ChangeNotifier {
  final HabitService _habitService;
  
  HabitAlarmProvider(this._habitService);

  Future<void> enableHabitAlarm(String habitId, DateTime time) async {
    final habit = _habitService.habits.firstWhere((h) => h.id == habitId);
    final updatedHabit = habit.copyWith(
      hasAlarm: true,
      targetTime: time,
    );
    
    await _habitService.updateHabit(updatedHabit);
    await HabitAlarmService.scheduleHabitAlarm(updatedHabit);
    notifyListeners();
  }

  Future<void> disableHabitAlarm(String habitId) async {
    final habit = _habitService.habits.firstWhere((h) => h.id == habitId);
    final updatedHabit = habit.copyWith(hasAlarm: false);
    
    await _habitService.updateHabit(updatedHabit);
    await HabitAlarmService.cancelHabitAlarm(habitId);
    notifyListeners();
  }

  Future<void> updateHabitAlarmTime(String habitId, DateTime time) async {
    final habit = _habitService.habits.firstWhere((h) => h.id == habitId);
    final updatedHabit = habit.copyWith(targetTime: time);
    
    await _habitService.updateHabit(updatedHabit);
    if (habit.hasAlarm) {
      await HabitAlarmService.scheduleHabitAlarm(updatedHabit);
    }
    notifyListeners();
  }

  Future<void> refreshAllAlarms() async {
    final activeHabits = _habitService.getActiveHabits();
    await HabitAlarmService.scheduleAllHabitAlarms(activeHabits);
    notifyListeners();
  }
}