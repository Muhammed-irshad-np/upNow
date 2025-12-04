import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _is24HourFormatKey = 'is_24_hour_format';
  static const String _wakeUpAlarmReminderDismissedKey =
      'wake_up_alarm_reminder_dismissed';
  static const String _isHapticFeedbackEnabledKey =
      'is_haptic_feedback_enabled';

  // Time Format
  static Future<bool> is24HourFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_is24HourFormatKey) ?? false; // Default to 12-hour
  }

  static Future<void> set24HourFormat(bool is24Hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_is24HourFormatKey, is24Hour);
  }

  // Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  // Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }

  // Wake-up alarm reminder dismissed state
  static Future<bool> isWakeUpAlarmReminderDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wakeUpAlarmReminderDismissedKey) ?? false;
  }

  static Future<void> setWakeUpAlarmReminderDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakeUpAlarmReminderDismissedKey, dismissed);
  }

  // Haptic feedback enabled state
  static Future<bool> isHapticFeedbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isHapticFeedbackEnabledKey) ??
        true; // Default to enabled
  }

  static Future<void> setHapticFeedbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isHapticFeedbackEnabledKey, enabled);
  }

  // Generic method to get a boolean value
  static Future<bool?> getBoolValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  // Generic method to set a boolean value
  static Future<void> setBoolValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
