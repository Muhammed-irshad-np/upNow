import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/services/permissions_manager.dart';
import 'package:upnow/utils/app_theme.dart';

enum AlarmOptimizationStyle {
  card, // Card style with ExpansionTile (for alarm screen)
  settingsTile, // Settings tile style (for settings screen)
}

class AlarmOptimizationCard extends StatefulWidget {
  final AlarmOptimizationStyle style;
  final bool hideWhenOptimized; // Hide when score == 3
  final bool isLast; // For settings tile - is this the last item in group?
  
  const AlarmOptimizationCard({
    Key? key,
    this.style = AlarmOptimizationStyle.card,
    this.hideWhenOptimized = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<AlarmOptimizationCard> createState() => _AlarmOptimizationCardState();
}

class _AlarmOptimizationCardState extends State<AlarmOptimizationCard> {
  bool _loading = true;
  int _score = 0;
  late Map<String, bool> _statuses;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    final statuses = await PermissionsManager.getOptimizationStatuses();
    final score = await PermissionsManager.getOptimizationScore();
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _score = score;
      _loading = false;
    });
  }

  Future<void> _requestOverlay() async {
    await PermissionsManager.requestDisplayOverApps(context);
    await _refresh();
  }

  Future<void> _requestBattery() async {
    await PermissionsManager.requestBatteryOptimization(context);
    await _refresh();
  }

  Future<void> _requestNotifications() async {
    await PermissionsManager.requestNotifications(context);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    // Hide when optimized if requested
    if (widget.hideWhenOptimized && _score == 3) {
      return const SizedBox.shrink();
    }

    if (widget.style == AlarmOptimizationStyle.settingsTile) {
      return _buildSettingsTile();
    } else {
      return _buildCardExpansionTile();
    }
  }

  Widget _buildCardExpansionTile() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.10),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.20), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
          leading: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.shield_moon_outlined, color: AppTheme.primaryColor, size: 20.sp),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alarm Optimization',
                style: TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _score == 3
                    ? 'All set. Alarms will work great.'
                    : 'Turn these on for reliable alarms.',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBadge(score: _score, showPercentage: true),
              SizedBox(width: 8.w),
              Icon(Icons.expand_more, color: AppTheme.secondaryTextColor, size: 20.sp),
            ],
          ),
          children: [
            _PermissionRow(
              icon: Icons.layers_outlined,
              title: 'Display over other apps',
              granted: _statuses['overlay'] ?? false,
              onFix: _requestOverlay,
            ),
            _Divider(),
            _PermissionRow(
              icon: Icons.battery_charging_full,
              title: 'Ignore battery optimizations',
              granted: _statuses['battery'] ?? false,
              onFix: _requestBattery,
            ),
            _Divider(),
            _PermissionRow(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              granted: _statuses['notifications'] ?? false,
              onFix: _requestNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile() {
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          childrenPadding: EdgeInsets.only(left: 54.w, right: 16.w, bottom: 12.h),
          shape: widget.isLast
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                )
              : null,
          collapsedShape: widget.isLast
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                )
              : null,
          leading: Icon(
            Icons.shield_moon_outlined,
            color: AppTheme.primaryColor.withOpacity(0.8),
            size: 22.sp,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alarm Optimization',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.primaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _score == 3
                    ? 'All set. Alarms will work great.'
                    : 'Turn these on for reliable alarms.',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBadge(score: _score, showPercentage: true),
              SizedBox(width: 8.w),
              Icon(Icons.expand_more, color: AppTheme.secondaryTextColor, size: 20.sp),
            ],
          ),
          children: [
            Column(
              children: [
                _PermissionRow(
                  icon: Icons.layers_outlined,
                  title: 'Display over other apps',
                  granted: _statuses['overlay'] ?? false,
                  onFix: _requestOverlay,
                ),
                SizedBox(height: 8.h),
                _PermissionRow(
                  icon: Icons.battery_charging_full,
                  title: 'Ignore battery optimizations',
                  granted: _statuses['battery'] ?? false,
                  onFix: _requestBattery,
                ),
                SizedBox(height: 8.h),
                _PermissionRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  granted: _statuses['notifications'] ?? false,
                  onFix: _requestNotifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      height: 1,
      color: AppTheme.darkBackground.withOpacity(0.5),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final bool showPercentage;
  const _ScoreBadge({required this.score, this.showPercentage = false});

  @override
  Widget build(BuildContext context) {
    final String label = showPercentage 
        ? '${((score / 3) * 100).round()}%'
        : '$score/3';
    final Color bg = score == 3
        ? Colors.green.withOpacity(0.20)
        : (score == 2 ? Colors.orange.withOpacity(0.20) : Colors.red.withOpacity(0.20));
    final Color fg = score == 3 ? Colors.greenAccent : (score == 2 ? Colors.orange : Colors.redAccent);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.sp)),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool granted;
  final Future<void> Function() onFix;
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.granted,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: granted ? Colors.greenAccent : AppTheme.primaryColor.withOpacity(0.8), size: 18.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!granted)
          TextButton(
            onPressed: onFix,
            child: const Text('Fix'),
          )
        else
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 18.sp),
      ],
    );
  }
}


