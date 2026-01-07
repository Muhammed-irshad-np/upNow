import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/settings_provider.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onDelete;
  final VoidCallback? onSkipOnce;
  final Function(bool) onToggle;
  final VoidCallback onTap;
  final Color cardColor;
  final double stackOffset;
  final bool isMorningAlarm;

  const AlarmCard({
    Key? key,
    required this.alarm,
    required this.onDelete,
    this.onSkipOnce,
    required this.onToggle,
    required this.onTap,
    required this.cardColor,
    this.stackOffset = 0.0,
    this.isMorningAlarm = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      height: 130.h, // Responsive height
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        // Use a gradient that blends the alarm color with a dark background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMorningAlarm
              ? [
                  Color.alphaBlend(
                      Colors.orange.withOpacity(0.3), const Color(0xFF121212)),
                  Color.alphaBlend(
                      Colors.yellow.withOpacity(0.2), const Color(0xFF000000)),
                ]
              : [
                  Color.alphaBlend(
                      cardColor.withOpacity(0.25), const Color(0xFF121212)),
                  Color.alphaBlend(
                      cardColor.withOpacity(0.1), const Color(0xFF000000)),
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: (isMorningAlarm ? Colors.orange : cardColor).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: Offset(0, 8.h),
          ),
          BoxShadow(
            color:
                (isMorningAlarm ? Colors.orange : cardColor).withOpacity(0.15),
            blurRadius: 32,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Decorative background glow
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isMorningAlarm ? Colors.orange : cardColor)
                      .withOpacity(0.2),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // First row - Label and More button
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMorningAlarm) ...[
                                    Icon(
                                      Icons.wb_sunny,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                  Flexible(
                                    child: Text(
                                      isMorningAlarm
                                          ? 'Wake-Up Alarm'
                                          : (alarm.label.isNotEmpty
                                              ? alarm.label
                                              : 'Alarm'),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // More options button aligned with label
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              color: Colors.white.withOpacity(0.7),
                              size: 18.sp,
                            ),
                            onSelected: (String value) {
                              switch (value) {
                                case 'delete':
                                  onDelete();
                                  break;
                                case 'skip_once':
                                  if (onSkipOnce != null) {
                                    onSkipOnce!();
                                  }
                                  break;
                              }
                            },
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            padding: EdgeInsets.zero,
                            splashRadius: 16.r,
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alarm.repeat != AlarmRepeat.once &&
                                  onSkipOnce != null)
                                PopupMenuItem<String>(
                                  value: 'skip_once',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.skip_next_outlined,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Skip once',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Second row - Time and Toggle
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                alarm.getFormattedTime(settings.is24HourFormat),
                                style: TextStyle(
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Toggle switch aligned with time
                          Transform.scale(
                            scale: 1.0,
                            child: Switch(
                              value: alarm.isEnabled,
                              onChanged: onToggle,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.white.withOpacity(0.35),
                              inactiveThumbColor: Colors.white.withOpacity(0.7),
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                      // Third row - Mission, Vibrate, and Frequency
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mission/Dismiss type indicator
                            _buildInfoIcon(
                              _getDismissTypeIcon(alarm.dismissType),
                              _getDismissTypeLabel(alarm.dismissType),
                            ),
                            SizedBox(width: 8.w),
                            // Vibration indicator
                            if (alarm.vibrate) ...[
                              _buildInfoIcon(
                                Icons.vibration,
                                'VIBRATE',
                              ),
                              SizedBox(width: 8.w),
                            ],
                            // Frequency/Repeat indicator
                            _buildInfoIcon(
                              _getFrequencyIcon(alarm.repeat),
                              isMorningAlarm
                                  ? 'DAILY'
                                  : alarm.repeatString.toUpperCase(),
                            ),
                            // Habit indicator
                            if (alarm.linkedHabitId != null) ...[
                              SizedBox(width: 8.w),
                              _buildInfoIcon(
                                Icons.check_circle_outline,
                                'HABIT',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10.sp,
            color: Colors.white,
          ),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 7.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDismissTypeIcon(DismissType dismissType) {
    switch (dismissType) {
      case DismissType.normal:
        return Icons.touch_app;
      case DismissType.math:
        return Icons.calculate;
      case DismissType.shake:
        return Icons.vibration;
      case DismissType.qrCode:
        return Icons.qr_code;
      case DismissType.typing:
        return Icons.keyboard;
      case DismissType.memory:
        return Icons.memory;
      case DismissType.barcode:
        return Icons.qr_code_scanner;
      case DismissType.swipe:
        return Icons.swipe;
    }
  }

  String _getDismissTypeLabel(DismissType dismissType) {
    switch (dismissType) {
      case DismissType.normal:
        return 'TAP';
      case DismissType.math:
        return 'MATH';
      case DismissType.shake:
        return 'SHAKE';
      case DismissType.qrCode:
        return 'QR CODE';
      case DismissType.typing:
        return 'TYPE';
      case DismissType.memory:
        return 'MEMORY';
      case DismissType.barcode:
        return 'BARCODE';
      case DismissType.swipe:
        return 'SWIPE';
    }
  }

  IconData _getFrequencyIcon(AlarmRepeat repeat) {
    switch (repeat) {
      case AlarmRepeat.once:
        return Icons.looks_one;
      case AlarmRepeat.daily:
        return Icons.repeat;
      case AlarmRepeat.weekdays:
        return Icons.work;
      case AlarmRepeat.weekends:
        return Icons.weekend;
      case AlarmRepeat.custom:
        return Icons.date_range;
    }
  }
}
