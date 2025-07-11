import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _is24HourFormatKey = 'is_24_hour_format';

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