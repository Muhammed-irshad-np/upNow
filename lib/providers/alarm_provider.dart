import 'package:flutter/foundation.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/services/alarm_service.dart';

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
} 