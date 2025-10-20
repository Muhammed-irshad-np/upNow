import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/services/permissions_manager.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/alarm_card.dart';
import 'package:upnow/widgets/gradient_button.dart';
// import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
// import 'package:upnow/database/hive_database.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/utils/global_error_handler.dart';
import 'package:upnow/utils/preferences_helper.dart';
import 'package:upnow/widgets/alarm_optimization_card.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  bool _isWakeUpReminderDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadWakeUpReminderState();
  }

  Future<void> _loadWakeUpReminderState() async {
    final dismissed = await PreferencesHelper.isWakeUpAlarmReminderDismissed();
    setState(() {
      _isWakeUpReminderDismissed = dismissed;
    });
  }

  Future<void> _dismissWakeUpReminder() async {
    await PreferencesHelper.setWakeUpAlarmReminderDismissed(true);
    setState(() {
      _isWakeUpReminderDismissed = true;
    });
  }

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
        titleSpacing: 20.w,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Alarm Optimization card at top of alarm screen (hide when all 3 permissions granted)
            const SliverToBoxAdapter(
              child: AlarmOptimizationCard(
                style: AlarmOptimizationStyle.card,
                hideWhenOptimized: true,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildNextAlarmSection(context, alarms),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 8.h),
            ),
            if (!_isWakeUpReminderDismissed && !alarmProvider.hasMorningAlarm)
              SliverToBoxAdapter(
                child: _buildWakeUpAlarmReminder(context),
              ),
            if (!_isWakeUpReminderDismissed && !alarmProvider.hasMorningAlarm)
              SliverToBoxAdapter(
                child: SizedBox(height: 8.h),
              ),
            SliverToBoxAdapter(
              child: _buildQuickAlarmButtons(context),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 8.h),
            ),
            alarms.isEmpty
              ? SliverPadding(
                  padding: EdgeInsets.only(bottom: 96.h),
                  sliver: SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.only(bottom: 96.h),
                  sliver: SliverToBoxAdapter(
                    child: _buildAlarmList(context, alarms),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'alarmFab',
        onPressed: () async {
          try {
            await Navigator.pushNamed(context, '/create_alarm');
          } catch (e, s) {
            // Ensure any navigation-related errors surface visibly
            GlobalErrorHandler.onException(e, s);
          }
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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

  // Format time based on user preference
  String _formatTime(int hour, int minute, bool is24Hour) {
    if (is24Hour) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$displayHour:$minuteStr $period';
    }
  }

  // Build the next alarm section
  Widget _buildNextAlarmSection(BuildContext context, List<dynamic> alarms) {
    final settings = Provider.of<SettingsProvider>(context);
    final nextAlarm = _findNextAlarm(alarms);
    
    if (nextAlarm == null) {
      return const SizedBox.shrink(); // Don't show anything if no next alarm
    }

    final nextAlarmTime = _getNextAlarmDateTime(nextAlarm, DateTime.now());
    final timeRemaining = _formatTimeRemaining(nextAlarmTime);
    final alarmTimeString = _formatTime(nextAlarm.hour, nextAlarm.minute, settings.is24HourFormat);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.schedule,
                color: AppTheme.primaryColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
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
                  SizedBox(height: 2.h),
                  Text(
                    alarmTimeString,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextAlarm.label.isNotEmpty) ...[
                    SizedBox(height: 2.h),
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

  // Morning alarm section removed; now highlighted as the first alarm card

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
               SizedBox(width: 10.w),
              const Text('Permissions Required'),
            ],
          ),
          content: Text(
            'we need to request some important permissions.',
            style: TextStyle(fontSize: 14.sp),
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
      // await PermissionsManager.requestExactAlarm(context);
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
            size: 100.sp,
            color: AppTheme.secondaryTextColor.withOpacity(0.5),
          ),
          SizedBox(height: 20.h),
          Text(
            'No alarms set',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Create an alarm to get started',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          SizedBox(height: 30.h),
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
    // Sort alarms: active alarms first, inactive alarms last
    final sortedAlarms = List<dynamic>.from(alarms);
    sortedAlarms.sort((a, b) {
      // Active alarms (isEnabled = true) come first
      if (a.isEnabled && !b.isEnabled) return -1;
      if (!a.isEnabled && b.isEnabled) return 1;
      return 0; // Keep original order for alarms with same status
    });

    // Ensure morning (wake-up) alarm is the first item if present and enabled
    final alarmProvider = Provider.of<AlarmProvider>(context);
    if (alarmProvider.isMorningAlarmEnabled) {
      final int morningIndex = sortedAlarms.indexWhere((a) => a.isMorningAlarm == true);
      if (morningIndex > 0) {
        final morningAlarm = sortedAlarms.removeAt(morningIndex);
        sortedAlarms.insert(0, morningAlarm);
      }
    }

    // Define vibrant colors for active alarms
    final List<Color> activeCardColors = [
      const Color(0xFF4A90E2), // Blue
      const Color(0xFF7ED321), // Green
      const Color(0xFFF5A623), // Orange/Yellow
      const Color(0xFFD0021B), // Red
      const Color(0xFF9013FE), // Purple
      const Color(0xFF50E3C2), // Teal
      const Color(0xFFBD10E0), // Magenta
      const Color(0xFFB8E986), // Light Green
    ];

    // Grey color for inactive alarms
    final Color inactiveCardColor = Colors.grey.shade600;

    // Calculate the height needed for stacked cards
    final double cardHeight = 150.h;
    final double stackOffset = 120.h; // Show more of each card while keeping stacked effect
    final double totalHeight = (sortedAlarms.length - 1) * stackOffset + cardHeight + 40.h;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: totalHeight,
      child: Stack(
        children: [
          // Build cards from bottom to top (reverse order for proper stacking)
          for (int i = sortedAlarms.length - 1; i >= 0; i--)
            Positioned(
              top: i * stackOffset,
              left: 0,
              right: 0,
              child: AlarmCard(
                alarm: sortedAlarms[i],
                cardColor: sortedAlarms[i].isEnabled 
                  ? activeCardColors[i % activeCardColors.length]
                  : inactiveCardColor,
                isMorningAlarm: sortedAlarms[i].isMorningAlarm == true,
                stackOffset: 0,
                onDelete: () {
                  Provider.of<AlarmProvider>(context, listen: false)
                      .deleteAlarm(sortedAlarms[i].id);
                },
                onToggle: (value) {
                  Provider.of<AlarmProvider>(context, listen: false)
                      .toggleAlarm(sortedAlarms[i].id, value);
                },
                onTap: () async {
                  // Navigate to edit alarm screen
                  await Navigator.pushNamed(
                    context,
                    '/edit_alarm',
                    arguments: sortedAlarms[i],
                  );
                  // AlarmProvider will automatically reload alarms
                },
                onSkipOnce: () => _skipAlarmOnce(context, sortedAlarms[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _skipAlarmOnce(BuildContext context, AlarmModel alarm) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    Provider.of<AlarmProvider>(context, listen: false).skipAlarmOnce(alarm.id);

    final timeString = alarm.getFormattedTime(settings.is24HourFormat);
    final message = alarm.label.isNotEmpty ? alarm.label : timeString;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message alarm skipped for next time.'),
        backgroundColor: AppTheme.darkSurface,
        duration: const Duration(seconds: 2),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
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
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Quick Alarms',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Quick Alarm Buttons
            Row(
              children: [
                _buildQuickAlarmButton(context, 5),
                SizedBox(width: 8.w),
                _buildQuickAlarmButton(context, 10),
                SizedBox(width: 8.w),
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
        height: 72.h,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _createQuickAlarm(context, minutes),
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$minutes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'min',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWakeUpAlarmReminder(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.wb_sunny,
                  color: AppTheme.primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Your Wake-Up Time',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Start your day right with a consistent wake-up routine',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // IconButton(
              //   onPressed: _dismissWakeUpReminder,
              //   icon: Icon(
              //     Icons.close,
              //     color: AppTheme.secondaryTextColor,
              //     size: 20.sp,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Set Time',
                 
                  gradient: AppTheme.primaryGradient,
                  icon: Icon(Icons.alarm_add, color: Colors.white, size: 18.sp),
                  onPressed: () async {
                    await _showWakeUpTimePicker(context);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              TextButton(
                onPressed: _dismissWakeUpReminder,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showWakeUpTimePicker(BuildContext context) async {
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    final currentTime = alarmProvider.morningAlarmTime;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        // Wrap with MediaQuery to use 12-hour format
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onSurface: AppTheme.textColor,
              ),
              timePickerTheme: TimePickerThemeData(
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    
    if (pickedTime != null) {
      await alarmProvider.setMorningAlarm(pickedTime.hour, pickedTime.minute);
      await _dismissWakeUpReminder();
    }
  }

  
} 