import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/alarm_card.dart';
import 'package:upnow/widgets/gradient_button.dart';

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
} 