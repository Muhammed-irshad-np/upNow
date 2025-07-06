import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onDelete;
  final Function(bool) onToggle;
  final VoidCallback onTap;
  final Color cardColor;
  final double stackOffset;

  const AlarmCard({
    Key? key,
    required this.alarm,
    required this.onDelete,
    required this.onToggle,
    required this.onTap,
    required this.cardColor,
    this.stackOffset = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h, // Responsive height
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                // Left side - Time and label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Time display
                      Text(
                        alarm.timeString,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Label or repeat info
                      Text(
                        alarm.label.isNotEmpty ? alarm.label : alarm.repeatString,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                                  // Right side - Controls and info
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Toggle switch
                      Transform.scale(
                        scale: 1.0,
                        child: Switch(
                          value: alarm.isEnabled,
                          onChanged: onToggle,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.3),
                          inactiveThumbColor: Colors.white.withOpacity(0.7),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      // Info chips row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Alarm type indicator
                          _buildInfoIcon(
                            _getDismissTypeIcon(alarm.dismissType),
                            _getDismissTypeLabel(alarm.dismissType),
                          ),
                          SizedBox(width: 6.w),
                          // Vibration indicator
                          if (alarm.vibrate)
                            _buildInfoIcon(
                              Icons.vibration,
                              'VIBRATE',
                            ),
                          SizedBox(width: 6.w),
                          // Delete button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              onPressed: onDelete,
                              constraints: BoxConstraints(
                                minWidth: 28.w,
                                minHeight: 28.h,
                              ),
                              padding: EdgeInsets.all(2.w),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
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
      default:
        return Icons.touch_app;
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
      default:
        return 'TAP';
    }
  }
} 