import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
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

class _HabitCheckButtonState extends State<HabitCheckButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
        widget.onToggle();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isAnimating) return;

    if (!widget.isCompleted) {
      HapticFeedbackHelper.trigger();
      setState(() {
        _isAnimating = true;
      });
      // The animation will start in the DotLottieLoader's onLoaded callback
      // once the composition is loaded and duration is known.
    } else {
      HapticFeedbackHelper.trigger();
      widget.onToggle();
    }
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
          child: _isAnimating
              ? DotLottieLoader.fromAsset(
                  'assets/images/Success.lottie',
                  frameBuilder: (context, dotlottie) {
                    if (dotlottie != null) {
                      return Lottie.memory(
                        dotlottie.animations.values.first,
                        controller: _controller,
                        onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          _controller.forward(from: 0);
                        },
                        width: iconSize,
                        height: iconSize,
                      );
                    } else {
                      return SizedBox(width: iconSize, height: iconSize);
                    }
                  },
                )
              : Icon(
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
