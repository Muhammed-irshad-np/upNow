import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WakeupTimePage extends StatefulWidget {
  const WakeupTimePage({super.key});

  @override
  State<WakeupTimePage> createState() => _WakeupTimePageState();
}

class _WakeupTimePageState extends State<WakeupTimePage> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    // Initialize with default 7:00 AM or current morning alarm time
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    final morningTime = alarmProvider.morningAlarmTime;
    final now = DateTime.now();
    _selectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      morningTime.hour,
      morningTime.minute,
    );

    // Ensure the provider is updated with the initial values if not already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!alarmProvider.hasMorningAlarm) {
        alarmProvider.setMorningAlarm(morningTime.hour, morningTime.minute);
      }
    });
  }

  void _onTimeChanged(DateTime newTime) {
    setState(() {
      _selectedTime = newTime;
    });

    // Update provider immediately
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.updateMorningAlarm(newTime.hour, newTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 48.sp,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Wake Up Time',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'Set your daily wake up time to start your day right.',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.secondaryTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40.h),
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                onDateTimeChanged: _onTimeChanged,
                use24hFormat:
                    false, // Or dynamic based on settings if needed, but standard is fine mostly
              ),
            ),
          ),
        ],
      ),
    );
  }
}
