import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:path/path.dart' as p;

class AlarmFormProvider with ChangeNotifier {
  late TimeOfDay _selectedTime;
  String _label = 'Alarm';
  DismissType _dismissType = DismissType.math;
  AlarmRepeat _repeat = AlarmRepeat.once;
  List<bool> _weekdays = List.filled(7, false);
  bool _vibrate = true;
  String? _selectedSoundPath;
  bool _isMorningAlarm = false;

  final List<String> availableSounds = const [
    'alarm',
    'eas_alarm_iphone_alarm_262882',
    'fire_alarm',
    'iphone_alarm',
    'lo_fi_alarm_clock_243766',
    'lofi',
    'loudest_alarm',
    'loudest_alarm_clock',
    'morning_flower',
    'motivational_alarm',
    'perfect_alarm',
    'rooster_alarm',
    'simplified',
    'south_korea_eas_alarm_1966_422162',
    'stardust',
    'thailand_eas_alarm_2006_266492',
    'wake_up',
  ];

  AlarmFormProvider({AlarmModel? initial}) {
    if (initial != null) {
      _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);
      _label = initial.label;
      _dismissType = initial.dismissType;
      _repeat = initial.repeat;
      _weekdays = List<bool>.from(initial.weekdays);
      _vibrate = initial.vibrate;
      if (initial.soundPath.isNotEmpty) {
        _selectedSoundPath = p.basenameWithoutExtension(initial.soundPath);
      } else {
        _selectedSoundPath = initial.soundPath;
      }
      _isMorningAlarm = initial.isMorningAlarm;
    } else {
      final now = TimeOfDay.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  // Getters
  TimeOfDay get selectedTime => _selectedTime;
  String get label => _label;
  DismissType get dismissType => _dismissType;
  AlarmRepeat get repeat => _repeat;
  List<bool> get weekdays => _weekdays;
  bool get vibrate => _vibrate;
  String? get selectedSoundPath => _selectedSoundPath;
  bool get isMorningAlarm => _isMorningAlarm;

  // Setters
  void setLabel(String value) {
    if (_label != value) {
      _label = value;
      notifyListeners();
    }
  }

  void setDismissType(DismissType type) {
    if (_dismissType != type) {
      _dismissType = type;
      notifyListeners();
    }
  }

  void setRepeat(AlarmRepeat value) {
    if (_repeat != value) {
      _repeat = value;
      notifyListeners();
    }
  }

  void toggleWeekday(int index) {
    _weekdays[index] = !_weekdays[index];
    notifyListeners();
  }

  void setVibrate(bool value) {
    _vibrate = value;
    notifyListeners();
  }

  void setMorningAlarm(bool value) {
    _isMorningAlarm = value;
    if (value && _repeat == AlarmRepeat.once) {
      _repeat = AlarmRepeat.daily;
    }
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setSelectedSoundPath(String? path) {
    _selectedSoundPath = path;
    notifyListeners();
  }

  Future<void> stopPreview() async {
    await AlarmService.stopPreview();
  }

  Future<void> previewSound(String soundName) async {
    await AlarmService.previewSound(soundName);
  }

  AlarmModel buildOrUpdate(AlarmModel? existing) {
    final alarm = existing ??
        AlarmModel(hour: _selectedTime.hour, minute: _selectedTime.minute);
    alarm.hour = _selectedTime.hour;
    alarm.minute = _selectedTime.minute;
    alarm.label = _label.isEmpty ? 'Alarm' : _label;
    alarm.dismissType = _dismissType;
    alarm.repeat = _repeat;
    alarm.weekdays = _weekdays;
    alarm.vibrate = _vibrate;
    alarm.soundPath = _selectedSoundPath ?? '';
    alarm.isMorningAlarm = _isMorningAlarm;
    return alarm;
  }
}
