import 'package:flutter/material.dart';
import 'package:upnow/utils/preferences_helper.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;

  bool get is24HourFormat => _is24HourFormat;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _is24HourFormat = await PreferencesHelper.is24HourFormat();
    notifyListeners();
  }

  Future<void> updateTimeFormat(bool is24Hour) async {
    _is24HourFormat = is24Hour;
    await PreferencesHelper.set24HourFormat(is24Hour);
    notifyListeners();
  }
} 