import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:upnow/models/alarm_model.dart';

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
    'assets/sounds/stardust.mp3',
    'assets/sounds/simplified.mp3',
    'assets/sounds/lofi.mp3',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  AlarmFormProvider({AlarmModel? initial}) {
    if (initial != null) {
      _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);
      _label = initial.label;
      _dismissType = initial.dismissType;
      _repeat = initial.repeat;
      _weekdays = List<bool>.from(initial.weekdays);
      _vibrate = initial.vibrate;
      _selectedSoundPath = initial.soundPath;
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
    await _audioPlayer.stop();
  }

  Future<void> previewSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      final relative = assetPath.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(relative));
    } catch (_) {
      // ignore preview errors for now
    }
  }

  AlarmModel buildOrUpdate(AlarmModel? existing) {
    final alarm = existing ?? AlarmModel(hour: _selectedTime.hour, minute: _selectedTime.minute);
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}


