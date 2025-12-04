import 'package:flutter/services.dart';

class HapticFeedbackHelper {
  static Future<void> trigger() async {
    await HapticFeedback.lightImpact();
  }
}
