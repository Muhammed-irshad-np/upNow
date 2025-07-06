import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/services/permissions_manager.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/alarm_card.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context);
    final alarms = alarmProvider.alarms;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UpN',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
            Icon(
              Icons.alarm,
              size: 22.sp,
              color: AppTheme.primaryColor,
            ),
            Text(
              'w',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
      ),
      body: Column(
        children: [
          _buildNextAlarmSection(context, alarms),
          const SizedBox(height: 8),
          _buildQuickAlarmButtons(context),
          const SizedBox(height: 8),
          Expanded(
            child: alarms.isEmpty
                ? _buildEmptyState(context)
                : _buildAlarmList(context, alarms),
          ),
        ],
      ),
    );
  }

  // Find the next upcoming alarm
  AlarmModel? _findNextAlarm(List<dynamic> alarms) {
    final now = DateTime.now();
    AlarmModel? nextAlarm;
    DateTime? nextAlarmTime;

    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;

      DateTime alarmDateTime = _getNextAlarmDateTime(alarm, now);
      
      if (nextAlarmTime == null || alarmDateTime.isBefore(nextAlarmTime)) {
        nextAlarmTime = alarmDateTime;
        nextAlarm = alarm;
      }
    }

    return nextAlarm;
  }

  // Calculate the next occurrence of an alarm
  DateTime _getNextAlarmDateTime(AlarmModel alarm, DateTime now) {
    DateTime alarmToday = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    
    // If the alarm time has passed today, schedule for tomorrow
    if (alarmToday.isBefore(now) || alarmToday.isAtSameMomentAs(now)) {
      return alarmToday.add(const Duration(days: 1));
    }
    
    return alarmToday;
  }

  // Format time remaining until alarm
  String _formatTimeRemaining(DateTime alarmTime) {
    final now = DateTime.now();
    final difference = alarmTime.difference(now);
    
    if (difference.inDays > 0) {
      return 'Rings in ${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return 'Rings in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return 'Rings in ${difference.inMinutes}m';
    } else {
      return 'Rings in less than 1m';
    }
  }

  // Format time to 12-hour format with AM/PM
  String _formatTo12Hour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  // Build the next alarm section
  Widget _buildNextAlarmSection(BuildContext context, List<dynamic> alarms) {
    final nextAlarm = _findNextAlarm(alarms);
    
    if (nextAlarm == null) {
      return const SizedBox.shrink(); // Don't show anything if no next alarm
    }

    final nextAlarmTime = _getNextAlarmDateTime(nextAlarm, DateTime.now());
    final timeRemaining = _formatTimeRemaining(nextAlarmTime);
    final alarmTimeString = _formatTo12Hour(nextAlarm.hour, nextAlarm.minute);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.schedule,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Alarm',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alarmTimeString,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextAlarm.label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      nextAlarm.label,
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeRemaining,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check and request critical permissions if needed
  Future<bool> _checkCriticalPermissions(BuildContext context) async {
    // Check if any critical permission is missing
    if (!await PermissionsManager.hasAllCriticalPermissions()) {
      // Show explanation dialog
      final bool shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notification_important, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              const Text('Permissions Required'),
            ],
          ),
          content: const Text(
            'To ensure alarms work correctly, we need to request some important permissions.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldContinue) {
        return false;
      }

      // Request permissions
      await PermissionsManager.requestNotifications(context);
      await PermissionsManager.requestDisplayOverApps(context);
      await PermissionsManager.requestBatteryOptimization(context);
      await PermissionsManager.requestExactAlarm(context);
    }

    return true;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 100,
            color: AppTheme.secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No alarms set',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create an alarm to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 30),
          GradientButton(
            text: 'Create Alarm',
            gradient: AppTheme.primaryGradient,
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              // Check for critical permissions before creating an alarm
              if (!await _checkCriticalPermissions(context)) {
                return;
              }
              
              // Navigate to create alarm screen
              await Navigator.pushNamed(context, '/create_alarm');
              // AlarmProvider will automatically reload alarms
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(BuildContext context, List<dynamic> alarms) {
    // Define vibrant colors for the stacked cards
    final List<Color> cardColors = [
      const Color(0xFF4A90E2), // Blue
      const Color(0xFF7ED321), // Green
      const Color(0xFFF5A623), // Orange/Yellow
      const Color(0xFFD0021B), // Red
      const Color(0xFF9013FE), // Purple
      const Color(0xFF50E3C2), // Teal
      const Color(0xFFBD10E0), // Magenta
      const Color(0xFFB8E986), // Light Green
    ];

    // Calculate the height needed for stacked cards
    final double cardHeight = 150.h;
    final double stackOffset = 120.h; // Show more of each card while keeping stacked effect
    final double totalHeight = (alarms.length - 1) * stackOffset + cardHeight + 40.h;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Build cards from bottom to top (reverse order for proper stacking)
            for (int i = alarms.length - 1; i >= 0; i--)
              Positioned(
                top: i * stackOffset,
                left: 0,
                right: 0,
                child: AlarmCard(
                  alarm: alarms[i],
                  cardColor: cardColors[i % cardColors.length],
                  stackOffset: 0,
                  onDelete: () {
                    Provider.of<AlarmProvider>(context, listen: false)
                        .deleteAlarm(alarms[i].id);
                  },
                  onToggle: (value) {
                    Provider.of<AlarmProvider>(context, listen: false)
                        .toggleAlarm(alarms[i].id, value);
                  },
                  onTap: () async {
                    // Navigate to edit alarm screen
                    await Navigator.pushNamed(
                      context,
                      '/edit_alarm',
                      arguments: alarms[i],
                    );
                    // AlarmProvider will automatically reload alarms
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to create and schedule a quick alarm
  Future<void> _createQuickAlarm(BuildContext context, int minutes) async {
    try {
      debugPrint('QUICK ALARM: Starting quick alarm creation for $minutes minutes...');

      // Check for critical permissions before creating an alarm
      if (!await _checkCriticalPermissions(context)) {
        return;
      }

      final now = DateTime.now();
      final alarmTime = now.add(Duration(minutes: minutes));
      final alarmHour = alarmTime.hour;
      final alarmMinute = alarmTime.minute;

      debugPrint('QUICK ALARM: New quick alarm time set to ${alarmHour}:${alarmMinute}');

      final AlarmModel newAlarm = AlarmModel(
        hour: alarmHour,
        minute: alarmMinute,
        isEnabled: true,
        dismissType: DismissType.normal,
        vibrate: true,
        repeat: AlarmRepeat.once,
        label: 'Quick Alarm - $minutes min', 
      );

      debugPrint('QUICK ALARM: Created quick alarm with label: ${newAlarm.label}');

      // Use AlarmProvider to add the alarm, which handles saving, scheduling, and UI update
      await Provider.of<AlarmProvider>(context, listen: false).addAlarm(newAlarm);
      debugPrint('QUICK ALARM: Alarm added via AlarmProvider.');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick alarm set for $minutes minutes (${alarmHour}:${alarmMinute.toString().padLeft(2, '0')})'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('QUICK ALARM: Quick alarm creation process completed successfully');
    } catch (e, stackTrace) {
      debugPrint('QUICK ALARM ERROR: $e');
      debugPrint('QUICK ALARM STACK TRACE: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating quick alarm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuickAlarmButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title for Quick Alarms
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Alarms',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick Alarm Buttons
            Row(
              children: [
                _buildQuickAlarmButton(context, 5),
                const SizedBox(width: 8),
                _buildQuickAlarmButton(context, 10),
                const SizedBox(width: 8),
                _buildQuickAlarmButton(context, 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAlarmButton(BuildContext context, int minutes) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _createQuickAlarm(context, minutes),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'min',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add a new test method to create an alarm directly from the alarm screen for testing
  static Future<void> createAndScheduleTestAlarm(BuildContext context) async {
    try {
      debugPrint('ALARM CREATION: Starting alarm creation process...');
      
      // Create a new alarm using the current time plus 5 minutes
      final now = DateTime.now();
      final alarmTime = now.add(const Duration(minutes: 5));
      final alarmHour = alarmTime.hour;
      final alarmMinute = alarmTime.minute;
      
      debugPrint('ALARM CREATION: New alarm time set to ${alarmHour}:${alarmMinute}');
      
      final AlarmModel newAlarm = AlarmModel(
        hour: alarmHour,
        minute: alarmMinute,
        isEnabled: true,
        dismissType: DismissType.normal,
        vibrate: true,
        repeat: AlarmRepeat.once,
      );
      
      // Add a special label to help identify the alarm in logs
      newAlarm.label = 'Test Alarm - ${DateTime.now().millisecondsSinceEpoch % 10000}';
      debugPrint('ALARM CREATION: Created alarm with label: ${newAlarm.label}');
      
      // Save the new alarm to the database
      debugPrint('ALARM CREATION: Saving to database...');
      await HiveDatabase.saveAlarm(newAlarm);
      
      // Verify the alarm was saved by retrieving all alarms
      final alarms = HiveDatabase.getAllAlarms();
      debugPrint('ALARM CREATION: Total alarms in database: ${alarms.length}');
      for (final a in alarms) {
        debugPrint('ALARM CREATION: Stored alarm: ${a.id} - ${a.hour}:${a.minute} - ${a.label}');
      }
      
      // Find the alarm we just saved in the database
      final savedAlarm = alarms.firstWhere(
        (a) => a.label == newAlarm.label, 
        orElse: () => throw Exception('Alarm not found in database after saving')
      );
      debugPrint('ALARM CREATION: Successfully found saved alarm with ID: ${savedAlarm.id}');
      
      // Schedule the alarm
      debugPrint('ALARM CREATION: Scheduling alarm...');
      try {
        await AlarmService.scheduleAlarm(savedAlarm);
        debugPrint('ALARM CREATION: Alarm scheduled successfully');
      } catch (e, stackTrace) {
        debugPrint('ALARM CREATION: Error scheduling alarm: $e');
        debugPrint('ALARM CREATION: Stack trace: $stackTrace');
        
        // Show error to user but don't prevent alarm creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm created but scheduling failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      // Verify pending notifications
      final notifications = FlutterLocalNotificationsPlugin();
      final pending = await notifications.pendingNotificationRequests();
      debugPrint('ALARM CREATION: Pending notifications: ${pending.length}');
      for (final p in pending) {
        debugPrint('ALARM CREATION: Pending notification: ${p.id} - ${p.title}');
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test alarm set for ${alarmHour}:${alarmMinute.toString().padLeft(2, '0')}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Final success log
      debugPrint('ALARM CREATION: Alarm creation process completed successfully');
    } catch (e, stackTrace) {
      debugPrint('ALARM CREATION ERROR: $e');
      debugPrint('ALARM CREATION STACK TRACE: $stackTrace');
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating alarm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 