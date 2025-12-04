import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/screens/settings/feedback_screen.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upnow/widgets/alarm_optimization_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

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
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          children: [
            _buildSectionTitle('Alarm'),
            _buildSettingGroup(
              children: [
                const AlarmOptimizationCard(
                  style: AlarmOptimizationStyle.settingsTile,
                  hideWhenOptimized: false,
                  isLast: false,
                ),
                Container(
                  height: 1.h,
                  color: AppTheme.darkBackground.withOpacity(0.5),
                ),
                _buildWakeUpAlarmSetting(context),
              ],
            ),
            SizedBox(height: 16.h),
            _buildSectionTitle('General'),
            _buildSettingGroup(
              children: [
                _buildTimeFormatSetting(context),
                Container(
                  height: 1.h,
                  color: AppTheme.darkBackground.withOpacity(0.5),
                ),
                _buildHapticFeedbackSetting(context),
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
            SizedBox(height: 16.h),
            _buildAppVersionTile(),
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
                      CupertinoPageRoute(
                          builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),
                _buildSettingTile(
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  onTap: () {
                    Share.share(
                        'Check out UpNow! https://play.google.com/store/apps/details?id=com.appweavers.upnow');
                  },
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
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
          isLast: false,
        );
      },
    );
  }

  Widget _buildHapticFeedbackSetting(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return _buildSettingTile(
          icon: Icons.vibration_outlined,
          title: 'Haptic Feedback',
          trailing: Switch(
            value: settings.isHapticFeedbackEnabled,
            onChanged: (bool value) {
              settings.updateHapticFeedback(value);
            },
            activeColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
          ),
          isLast: false,
        );
      },
    );
  }

  Widget _buildWakeUpAlarmSetting(BuildContext context) {
    return Consumer<AlarmProvider>(
      builder: (context, alarmProvider, child) {
        final hasMorningAlarm = alarmProvider.hasMorningAlarm;
        final isMorningAlarmEnabled = alarmProvider.isMorningAlarmEnabled;
        final morningAlarmTime = alarmProvider.morningAlarmTime;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              // Main wake-up alarm toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedbackHelper.trigger();
                    if (!hasMorningAlarm) {
                      // Create new morning alarm with default time
                      await alarmProvider.setMorningAlarm(7, 0);
                    } else {
                      await alarmProvider
                          .toggleMorningAlarm(!isMorningAlarmEnabled);
                    }
                  },
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      border: isMorningAlarmEnabled
                          ? Border(
                              bottom: BorderSide(
                                color: AppTheme.darkBackground.withOpacity(0.5),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm_on_outlined,
                          color: AppTheme.primaryColor.withOpacity(0.8),
                          size: 22.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wake-Up Alarm',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: AppTheme.primaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMorningAlarmEnabled) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  'Daily at ${morningAlarmTime.format(context)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Switch(
                          value: isMorningAlarmEnabled,
                          onChanged: (bool value) async {
                            HapticFeedbackHelper.trigger();
                            if (value) {
                              if (!hasMorningAlarm) {
                                // Create new morning alarm with default time
                                await alarmProvider.setMorningAlarm(7, 0);
                              } else {
                                // Enable existing morning alarm
                                await alarmProvider.toggleMorningAlarm(true);
                              }
                            } else {
                              // Disable morning alarm
                              await alarmProvider.toggleMorningAlarm(false);
                            }
                          },
                          activeColor: AppTheme.primaryColor,
                          activeTrackColor:
                              AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Time picker option (only shown when enabled)
              if (isMorningAlarmEnabled)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedbackHelper.trigger();
                      _showMorningAlarmTimePicker(context, alarmProvider);
                    },
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(16.r)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      child: Row(
                        children: [
                          SizedBox(width: 38.w), // Align with the text above
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_outlined,
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 16.w),
                                Text(
                                  'Set Wake-Up Time',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: AppTheme.primaryTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            morningAlarmTime.format(context),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12.sp,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMorningAlarmTimePicker(
      BuildContext context, AlarmProvider alarmProvider) async {
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
      await alarmProvider.updateMorningAlarm(
          pickedTime.hour, pickedTime.minute);
    }
  }

  Widget _buildAppVersionTile() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final String displayText;
        if (snapshot.hasData) {
          final info = snapshot.data!;
          // Example: 1.0.0 (6)
          displayText = '${info.version} (${info.buildNumber})';
        } else {
          displayText = '—';
        }

        return _buildSettingTile(
          icon: Icons.info_outline,
          title: 'App Version',
          trailing: Text(
            displayText,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          isLast: true,
        );
      },
    );
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
        onTap: () {
          if (onTap != null) {
            HapticFeedbackHelper.trigger();
            onTap();
          }
        },
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
              Icon(icon,
                  color: AppTheme.primaryColor.withOpacity(0.8), size: 22.sp),
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
