import 'package:flutter/material.dart';
import 'package:upnow/utils/preferences_helper.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;
  bool _isHapticFeedbackEnabled = true;

  bool get is24HourFormat => _is24HourFormat;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _is24HourFormat = await PreferencesHelper.is24HourFormat();
    _isHapticFeedbackEnabled =
        await PreferencesHelper.isHapticFeedbackEnabled();
    notifyListeners();
  }

  Future<void> updateTimeFormat(bool is24Hour) async {
    _is24HourFormat = is24Hour;
    await PreferencesHelper.set24HourFormat(is24Hour);
    notifyListeners();
  }

  Future<void> updateHapticFeedback(bool enabled) async {
    _isHapticFeedbackEnabled = enabled;
    await PreferencesHelper.setHapticFeedbackEnabled(enabled);
    notifyListeners();
  }
}
