import 'package:flutter/material.dart';
import 'package:upnow/utils/preferences_helper.dart';
import 'package:upnow/utils/app_theme.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;
  bool _isHapticFeedbackEnabled = true;
  bool _isDarkMode = true;
  AppThemeType _currentTheme = AppThemeType.tealOrange;

  bool get is24HourFormat => _is24HourFormat;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;
  bool get isDarkMode => _isDarkMode;
  AppThemeType get currentTheme => _currentTheme;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _is24HourFormat = await PreferencesHelper.is24HourFormat();
    _isHapticFeedbackEnabled =
        await PreferencesHelper.isHapticFeedbackEnabled();
    _isDarkMode = await PreferencesHelper.isDarkMode();
    AppTheme.isDarkMode = _isDarkMode;

    final themeName = await PreferencesHelper.getTheme();
    if (themeName != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (e) => e.toString() == themeName,
        orElse: () => AppThemeType.tealOrange,
      );
      AppTheme.currentTheme = _currentTheme;
    }
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

  Future<void> updateTheme(AppThemeType theme) async {
    _currentTheme = theme;
    AppTheme.currentTheme = theme;
    await PreferencesHelper.setTheme(theme.toString());
    notifyListeners();
  }

  Future<void> updateDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    AppTheme.isDarkMode = isDark;
    await PreferencesHelper.setDarkMode(isDark);
    notifyListeners();
  }
}
