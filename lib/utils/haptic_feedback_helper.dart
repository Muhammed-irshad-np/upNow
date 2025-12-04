import 'package:flutter/services.dart';
import 'package:upnow/utils/preferences_helper.dart';

class HapticFeedbackHelper {
  static Future<void> trigger() async {
    // Check if haptic feedback is enabled
    final isEnabled = await PreferencesHelper.isHapticFeedbackEnabled();

    if (!isEnabled) {
      return; // Don't trigger if disabled
    }

    // Use heavyImpact for stronger, more noticeable vibration
    await HapticFeedback.heavyImpact();
  }
}
