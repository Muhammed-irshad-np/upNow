import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';

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
                style: const TextStyle(
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
    final now = TimeOfDay.now();
    return Text(
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(
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
            Navigator.of(context).pop();
          },
        );
      case DismissType.math:
        return _buildMathProblem();
      case DismissType.shake:
        return const Text(
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
            Navigator.of(context).pop();
          },
        );
    }
  }
  
  Widget _buildMathProblem() {
    // Simple math problem implementation
    return Column(
      children: [
        const Text(
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
          style: const TextStyle(color: AppTheme.textColor),
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
              Navigator.of(context).pop();
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
      child: const Text(
        'Snooze for 10 minutes',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 16,
        ),
      ),
    );
  }
} 