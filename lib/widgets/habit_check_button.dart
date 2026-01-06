import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class HabitCheckButton extends StatefulWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onToggle;
  final double? size;

  const HabitCheckButton({
    Key? key,
    required this.isCompleted,
    required this.color,
    required this.onToggle,
    this.size,
  }) : super(key: key);

  @override
  State<HabitCheckButton> createState() => _HabitCheckButtonState();
}

class _HabitCheckButtonState extends State<HabitCheckButton> {
  void _handleTap() {
    HapticFeedbackHelper.trigger();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.size ?? 44.w;
    final double iconSize = buttonSize * 0.45;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color:
              widget.isCompleted ? widget.color : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: widget.isCompleted
                ? widget.color
                : widget.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: widget.isCompleted
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            Icons.check,
            color: widget.isCompleted
                ? Colors.white
                : widget.color.withOpacity(0.5),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
