import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/sleep_data_model.dart';

class SleepProvider extends ChangeNotifier {
  List<SleepDataModel> _sleepData = [];
  DateTime? _trackingStartTime;
  Timer? _trackingTimer;
  Duration _currentDuration = Duration.zero;
  
  // Getters
  List<SleepDataModel> get sleepData => _sleepData;
  bool get isTracking => _trackingStartTime != null;
  Duration get currentTrackingDuration => _currentDuration;
  
  SleepProvider() {
    _loadSleepData();
  }
  
  Future<void> _loadSleepData() async {
    _sleepData = HiveDatabase.getAllSleepData();
    _sleepData.sort((a, b) => b.sleepStart.compareTo(a.sleepStart)); // Most recent first
    notifyListeners();
  }
  
  Future<void> startTracking() async {
    if (_trackingStartTime != null) return; // Already tracking
    
    _trackingStartTime = DateTime.now();
    _currentDuration = Duration.zero;
    
    // Start a timer to update the duration every minute
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingStartTime != null) {
        _currentDuration = DateTime.now().difference(_trackingStartTime!);
        notifyListeners();
      }
    });
    
    notifyListeners();
  }
  
  Future<SleepDataModel?> stopTracking() async {
    if (_trackingStartTime == null) return null; // Not tracking
    
    final startTime = _trackingStartTime!;
    final endTime = DateTime.now();
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _trackingStartTime = null;
    _currentDuration = Duration.zero;
    
    // Calculate sleep duration in minutes
    final durationMinutes = endTime.difference(startTime).inMinutes;
    
    // Only save if duration is at least 10 minutes
    if (durationMinutes < 10) {
      notifyListeners();
      return null;
    }
    
    // Create mock data for deep sleep, REM, etc.
    final deepSleepMinutes = (durationMinutes * 0.25).round(); // ~25% deep sleep
    final remSleepMinutes = (durationMinutes * 0.23).round(); // ~23% REM sleep
    final awakeMinutes = (durationMinutes * 0.05).round(); // ~5% awake
    final lightSleepMinutes = durationMinutes - deepSleepMinutes - remSleepMinutes - awakeMinutes;
    
    // Calculate sleep efficiency (percentage of time actually asleep)
    final sleepEfficiency = (durationMinutes - awakeMinutes) / durationMinutes * 100;
    
    // Create sleep data model
    final sleepData = SleepDataModel(
      sleepStart: startTime,
      sleepEnd: endTime,
      sleepDurationMinutes: durationMinutes,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      awakeMinutes: awakeMinutes,
      sleepEfficiency: sleepEfficiency,
    );
    
    // Save to database
    await HiveDatabase.saveSleepData(sleepData);
    
    // Reload data
    await _loadSleepData();
    
    return sleepData;
  }
  
  Future<void> deleteSleepRecord(String id) async {
    await HiveDatabase.deleteSleepData(id);
    await _loadSleepData();
  }
  
  double getAverageSleepScore() {
    if (_sleepData.isEmpty) return 0;
    
    double totalScore = 0;
    for (final data in _sleepData) {
      totalScore += data.getSleepScore();
    }
    
    return totalScore / _sleepData.length;
  }
  
  Duration getAverageSleepDuration() {
    if (_sleepData.isEmpty) return Duration.zero;
    
    int totalMinutes = 0;
    for (final data in _sleepData) {
      totalMinutes += data.sleepDurationMinutes;
    }
    
    return Duration(minutes: totalMinutes ~/ _sleepData.length);
  }
  
  List<SleepDataModel> getRecentSleepData(int days) {
    return HiveDatabase.getRecentSleepData(days);
  }
} 