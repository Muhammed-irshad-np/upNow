import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:intl/intl.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({Key? key, required this.alarm}) : super(key: key);

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildTimeDisplay(),
              const SizedBox(height: 16),
              Text(
                widget.alarm.label,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(flex: 2),
              _buildDismissOptions(),
              const SizedBox(height: 24),
              _buildSnoozeButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final settings = Provider.of<SettingsProvider>(context);
    final now = DateTime.now();

    final formattedTime = settings.is24HourFormat
        ? DateFormat.Hm().format(now) // HH:mm
        : DateFormat.jm().format(now); // h:mm a

    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDismissOptions() {
    // Different dismiss methods based on alarm settings
    switch (widget.alarm.dismissType) {
      case DismissType.normal:
        return GradientButton(
          text: 'Dismiss Alarm',
          onPressed: () {
            _dismissAlarm();
          },
        );
      case DismissType.math:
        return _buildMathProblem();
      case DismissType.shake:
        return Text(
          'Shake your phone to dismiss',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        );
      default:
        return GradientButton(
          text: 'Dismiss Alarm',
          onPressed: () {
            _dismissAlarm();
          },
        );
    }
  }

  // Handle alarm dismissal
  void _dismissAlarm() {
    // If this is a one-time alarm, we'll delete it automatically
    if (widget.alarm.repeat == AlarmRepeat.once) {
      // No need to do anything here, as the AlarmService will handle deletion
      // when the alarm fires in _rescheduleAlarmForNextOccurrence
      debugPrint('One-time alarm dismissed - will be removed automatically');
    }
    Navigator.of(context).pop();
  }

  Widget _buildMathProblem() {
    // Simple math problem implementation
    return Column(
      children: [
         Text(
          '8 + 7 = ?',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            filled: true,
            fillColor: AppTheme.darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            if (value == '15') {
              _dismissAlarm();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wrong answer, try again!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSnoozeButton() {
    return TextButton(
      onPressed: () {
        // Handle snooze logic here
        Navigator.of(context).pop(true); // true indicates snooze
      },
      child: Text(
        'Snooze for 10 minutes',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
