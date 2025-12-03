import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HabitActivityScreen extends StatefulWidget {
  final HabitModel habit;

  const HabitActivityScreen({Key? key, required this.habit}) : super(key: key);

  @override
  State<HabitActivityScreen> createState() => _HabitActivityScreenState();
}

class _HabitActivityScreenState extends State<HabitActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCompletion() async {
    setState(() {
      _isCompleted = true;
    });

    final habitService = Provider.of<HabitService>(context, listen: false);
    await habitService.markHabitCompleted(widget.habit.id, DateTime.now());

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit completed! Great job! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Close screen after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _handleSnooze() async {
    await HabitAlarmService.snoozeHabitAlarm(widget.habit.id, 15);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildIcon(),
              SizedBox(height: 32.h),
              _buildHabitInfo(),
              const Spacer(flex: 2),
              if (!_isCompleted) _buildSwipeToComplete(),
              if (_isCompleted) _buildCompletedState(),
              SizedBox(height: 24.h),
              if (!_isCompleted) _buildSnoozeButton(),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData = Icons.star;
    if (widget.habit.icon != null) {
      try {
        iconData = IconData(int.parse(widget.habit.icon!),
            fontFamily: 'MaterialIcons');
      } catch (e) {
        debugPrint('Error parsing icon code: $e');
      }
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: widget.habit.color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.habit.color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.habit.color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          iconData,
          size: 48.sp,
          color: widget.habit.color,
        ),
      ),
    );
  }

  Widget _buildHabitInfo() {
    return Column(
      children: [
        Text(
          widget.habit.name,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.habit.description != null &&
            widget.habit.description!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            widget.habit.description!,
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: 8.h),
        Text(
          DateFormat.jm().format(DateTime.now()),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeToComplete() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Swipe to Complete  >>>',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Dismissible(
            key: const Key('swipe_to_complete'),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (direction) async {
              await _handleCompletion();
              return false; // Don't actually dismiss the widget from tree
            },
            background: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30.r),
              ),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20.w),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            child: Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: widget.habit.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.habit.color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12.w),
          Text(
            'Completed!',
            style: TextStyle(
              color: Colors.green,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnoozeButton() {
    return TextButton(
      onPressed: _handleSnooze,
      child: Text(
        'Snooze for 15 minutes',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 16.sp,
        ),
      ),
    );
  }
}
