import 'package:flutter/foundation.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:flutter/material.dart'; // Added for TimeOfDay

class AlarmProvider extends ChangeNotifier {
  List<AlarmModel> _alarms = [];
  
  List<AlarmModel> get alarms => _alarms;
  
  AlarmProvider() {
    _loadAlarms();
  }
  
  Future<void> _loadAlarms() async {
    _alarms = HiveDatabase.getAllAlarms();
    _alarms.sort((a, b) {
      // Sort by hour and minute
      if (a.hour != b.hour) {
        return a.hour.compareTo(b.hour);
      }
      return a.minute.compareTo(b.minute);
    });
    notifyListeners();
  }
  
  Future<void> addAlarm(AlarmModel alarm) async {
    await HiveDatabase.saveAlarm(alarm);
    await AlarmService.scheduleAlarm(alarm);
    await _loadAlarms();
  }
  
  Future<void> updateAlarm(AlarmModel alarm) async {
    await HiveDatabase.saveAlarm(alarm);
    await AlarmService.scheduleAlarm(alarm);
    await _loadAlarms();
  }
  
  Future<void> deleteAlarm(String id) async {
    await AlarmService.cancelAlarm(id);
    await HiveDatabase.deleteAlarm(id);
    await _loadAlarms();
  }
  
  Future<void> toggleAlarm(String id, bool isEnabled) async {
    final alarm = HiveDatabase.getAlarm(id);
    if (alarm != null) {
      final updatedAlarm = alarm.copyWith(isEnabled: isEnabled);
      await HiveDatabase.saveAlarm(updatedAlarm);
      
      if (isEnabled) {
        await AlarmService.scheduleAlarm(updatedAlarm);
      } else {
        await AlarmService.cancelAlarm(id);
      }
      
      await _loadAlarms();
    }
  }
  
  List<AlarmModel> getActiveAlarms() {
    return _alarms.where((alarm) => alarm.isEnabled).toList();
  }
  
  AlarmModel? getNextAlarm() {
    final activeAlarms = getActiveAlarms();
    if (activeAlarms.isEmpty) return null;
    
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Find the next alarm today
    for (final alarm in activeAlarms) {
      if (alarm.hour > currentHour || 
          (alarm.hour == currentHour && alarm.minute > currentMinute)) {
        return alarm;
      }
    }
    
    // If no alarm found for today, return the first alarm for tomorrow
    return activeAlarms.first;
  }

  Future<void> skipAlarmOnce(String alarmId) async {
    final alarm = _alarms.firstWhere((a) => a.id == alarmId);
    // Logic to skip the next occurrence will be in the service
    await AlarmService.skipNextAlarm(alarm);
    notifyListeners();
  }

  // Quick Alarm
  Future<void> addQuickAlarm(Duration duration) async {
    final now = DateTime.now();
    // ... existing code ...
  }

  // Morning alarm specific methods
  List<AlarmModel> getMorningAlarms() {
    return _alarms.where((alarm) => alarm.isMorningAlarm).toList();
  }
  
  AlarmModel? getActiveMorningAlarm() {
    final morningAlarms = getMorningAlarms()
        .where((alarm) => alarm.isEnabled)
        .toList();
    
    if (morningAlarms.isEmpty) return null;
    
    // Sort by time to get the earliest morning alarm
    morningAlarms.sort((a, b) {
      if (a.hour != b.hour) {
        return a.hour.compareTo(b.hour);
      }
      return a.minute.compareTo(b.minute);
    });
    
    return morningAlarms.first;
  }
  
  Future<void> setMorningAlarm(int hour, int minute) async {
    // Remove any existing morning alarm
    final existingMorningAlarms = getMorningAlarms();
    for (final alarm in existingMorningAlarms) {
      await deleteAlarm(alarm.id);
    }
    
    // Create new morning alarm
    final morningAlarm = AlarmModel(
      hour: hour,
      minute: minute,
      label: 'Wake Up',
      isMorningAlarm: true,
      repeat: AlarmRepeat.daily,
    );
    
    await addAlarm(morningAlarm);
  }
  
  Future<void> updateMorningAlarm(int hour, int minute) async {
    final existingMorningAlarm = getActiveMorningAlarm();
    
    if (existingMorningAlarm != null) {
      // Update existing morning alarm
      final updatedAlarm = existingMorningAlarm.copyWith(
        hour: hour,
        minute: minute,
      );
      await updateAlarm(updatedAlarm);
    } else {
      // Create new morning alarm if none exists
      await setMorningAlarm(hour, minute);
    }
  }
  
  Future<void> toggleMorningAlarm(bool isEnabled) async {
    final morningAlarm = getActiveMorningAlarm();
    if (morningAlarm != null) {
      await toggleAlarm(morningAlarm.id, isEnabled);
    }
  }
  
  bool get hasMorningAlarm {
    return getMorningAlarms().isNotEmpty;
  }
  
  bool get isMorningAlarmEnabled {
    final morningAlarm = getActiveMorningAlarm();
    return morningAlarm?.isEnabled ?? false;
  }
  
  TimeOfDay get morningAlarmTime {
    final morningAlarm = getActiveMorningAlarm();
    if (morningAlarm != null) {
      return TimeOfDay(hour: morningAlarm.hour, minute: morningAlarm.minute);
    }
    return const TimeOfDay(hour: 7, minute: 0); // Default to 7:00 AM
  }
} 