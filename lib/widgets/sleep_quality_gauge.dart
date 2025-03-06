import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:upnow/utils/app_theme.dart';

class SleepQualityGauge extends StatelessWidget {
  final double qualityScore;
  final double size;
  final double strokeWidth;

  const SleepQualityGauge({
    Key? key,
    required this.qualityScore,
    this.size = 120,
    this.strokeWidth = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _SleepQualityPainter(
                progress: qualityScore / 100,
                progressColor: _getColorForScore(qualityScore),
                backgroundColor: AppTheme.darkCardColor.withOpacity(0.3),
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${qualityScore.round()}',
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                'Sleep Quality',
                style: TextStyle(
                  fontSize: size * 0.1,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getColorForScore(double score) {
    if (score < 40) {
      return Colors.red;
    } else if (score < 60) {
      return Colors.orange;
    } else if (score < 80) {
      return Colors.yellow;
    } else {
      return AppTheme.successColor;
    }
  }
}

class _SleepQualityPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _SleepQualityPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    
    // Paint for background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Paint for progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc (starts from -90° which is the top of the circle)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SleepQualityPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
} 