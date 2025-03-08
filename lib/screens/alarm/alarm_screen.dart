import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/alarm_card.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context);
    final alarms = alarmProvider.alarms;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Alarms'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: alarms.isEmpty 
          ? _buildEmptyState(context)
          : _buildAlarmList(context, alarms),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create alarm screen and refresh when returning
          final result = await Navigator.pushNamed(context, '/create_alarm');
          // The AlarmProvider will automatically reload the alarms when adding/updating
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return AlarmCard(
          alarm: alarm,
          onDelete: () {
            Provider.of<AlarmProvider>(context, listen: false).deleteAlarm(alarm.id);
          },
          onToggle: (value) {
            Provider.of<AlarmProvider>(context, listen: false).toggleAlarm(alarm.id, value);
          },
          onTap: () async {
            // Navigate to edit alarm screen
            await Navigator.pushNamed(
              context, 
              '/edit_alarm',
              arguments: alarm,
            );
            // AlarmProvider will automatically reload alarms
          },
        );
      },
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