import 'dart:io';

import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:upnow/screens/alarm/alarm_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/screens/settings/feedback_screen.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/providers/alarm_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        children: [
          _buildSectionTitle('General'),
          _buildSettingGroup(
            children: [
              _buildTimeFormatSetting(context),
              _buildSettingTile(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: Text(
                  'English',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                onTap: () {
                  // Future: Show language picker
                },
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 32.h),
          _buildSectionTitle('Morning Alarm'),
          _buildMorningAlarmSection(context),
          SizedBox(height: 32.h),
          _buildSectionTitle('Feedback'),
          _buildSettingGroup(
            children: [
              _buildSettingTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.share_outlined,
                title: 'Share App',
                onTap: () {
                  // Future: Implement share functionality
                },
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFormatSetting(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return _buildSettingTile(
          icon: Icons.schedule_outlined,
          title: 'Time Format',
          trailing: DropdownButton<bool>(
            value: settings.is24HourFormat,
            onChanged: (bool? newValue) {
              if (newValue != null) {
                settings.updateTimeFormat(newValue);
              }
            },
            items: const [
              DropdownMenuItem(
                value: false,
                child: Text('12-hour'),
              ),
              DropdownMenuItem(
                value: true,
                child: Text('24-hour'),
              ),
            ],
            underline: Container(),
            dropdownColor: AppTheme.darkSurface,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          isLast: false, // The language tile is now the last one in this group
        );
      },
    );
  }

  Widget _buildMorningAlarmSection(BuildContext context) {
    return Consumer<AlarmProvider>(
      builder: (context, alarmProvider, child) {
        final hasMorningAlarm = alarmProvider.hasMorningAlarm;
        final isMorningAlarmEnabled = alarmProvider.isMorningAlarmEnabled;
        final morningAlarmTime = alarmProvider.morningAlarmTime;
        
        return _buildSettingGroup(
          children: [
            _buildSettingTile(
              icon: Icons.alarm_on_outlined,
              title: 'Morning Wake-Up Alarm',
              trailing: Switch(
                value: isMorningAlarmEnabled,
                onChanged: (bool value) async {
                  if (value && !hasMorningAlarm) {
                    // Create new morning alarm with default time
                    await alarmProvider.setMorningAlarm(7, 0);
                  } else {
                    await alarmProvider.toggleMorningAlarm(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
              isLast: !isMorningAlarmEnabled,
            ),
            if (isMorningAlarmEnabled)
              _buildSettingTile(
                icon: Icons.access_time_outlined,
                title: 'Wake-Up Time',
                trailing: Text(
                  morningAlarmTime.format(context),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                onTap: () => _showMorningAlarmTimePicker(context, alarmProvider),
                isLast: true,
              ),
          ],
        );
      },
    );
  }

  Future<void> _showMorningAlarmTimePicker(BuildContext context, AlarmProvider alarmProvider) async {
    final currentTime = alarmProvider.morningAlarmTime;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.darkSurface,
              dialBackgroundColor: AppTheme.darkBackground,
              hourMinuteTextColor: AppTheme.primaryTextColor,
              hourMinuteColor: AppTheme.primaryColor.withOpacity(0.1),
              dialHandColor: AppTheme.primaryColor,
              dialTextColor: AppTheme.primaryTextColor,
              helpTextStyle: TextStyle(color: AppTheme.primaryTextColor),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      await alarmProvider.updateMorningAlarm(pickedTime.hour, pickedTime.minute);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.secondaryTextColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? BorderRadius.vertical(bottom: Radius.circular(16.r))
            : BorderRadius.zero,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBackground.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor.withOpacity(0.8), size: 22.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: AppTheme.secondaryTextColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 