import 'dart:async';
import 'dart:math';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/sleep_data_model.dart';
import 'package:uuid/uuid.dart';

class SleepService {
  static Timer? _sleepTimer;
  static DateTime? _sleepStartTime;
  static bool _isSleepTracking = false;
  
  static bool get isSleepTracking => _isSleepTracking;
  static DateTime? get sleepStartTime => _sleepStartTime;
  
  static void startSleepTracking() {
    if (_isSleepTracking) return;
    
    _isSleepTracking = true;
    _sleepStartTime = DateTime.now();
    
    // Start a timer to update UI if needed
    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // This is just to trigger UI updates if needed
    });
  }
  
  static Future<SleepDataModel> stopSleepTracking() async {
    if (!_isSleepTracking || _sleepStartTime == null) {
      throw Exception('Sleep tracking not active');
    }
    
    final sleepEndTime = DateTime.now();
    _sleepTimer?.cancel();
    _sleepTimer = null;
    
    // Calculate sleep duration in minutes
    final sleepDuration = sleepEndTime.difference(_sleepStartTime!);
    final sleepDurationMinutes = sleepDuration.inMinutes;
    
    // For MVP, we'll generate some reasonable sleep stage data
    // In a real app, this would come from sensors or algorithms
    final deepSleepMinutes = (sleepDurationMinutes * 0.25).round(); // ~25% deep sleep
    final remSleepMinutes = (sleepDurationMinutes * 0.20).round();  // ~20% REM sleep
    final awakeMinutes = (sleepDurationMinutes * 0.05).round();     // ~5% awake time
    final lightSleepMinutes = sleepDurationMinutes - deepSleepMinutes - remSleepMinutes - awakeMinutes;
    
    // Calculate sleep efficiency (time asleep / time in bed)
    final sleepEfficiency = (sleepDurationMinutes - awakeMinutes) / sleepDurationMinutes;
    
    // Create sleep data model
    final sleepData = SleepDataModel(
      id: const Uuid().v4(),
      sleepStart: _sleepStartTime!,
      sleepEnd: sleepEndTime,
      sleepDurationMinutes: sleepDurationMinutes,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      awakeMinutes: awakeMinutes,
      sleepEfficiency: sleepEfficiency,
    );
    
    // Save to database
    await HiveDatabase.saveSleepData(sleepData);
    
    // Reset tracking state
    _isSleepTracking = false;
    _sleepStartTime = null;
    
    return sleepData;
  }
  
  static List<SleepDataModel> getRecentSleepData(int days) {
    return HiveDatabase.getRecentSleepData(days);
  }
  
  static Map<String, dynamic> getAverageSleepMetrics(int days) {
    final sleepData = HiveDatabase.getRecentSleepData(days);
    
    if (sleepData.isEmpty) {
      return {
        'averageDuration': 0,
        'averageEfficiency': 0.0,
        'averageDeepSleep': 0.0,
        'averageRemSleep': 0.0,
        'averageLightSleep': 0.0,
        'averageAwake': 0.0,
      };
    }
    
    int totalDuration = 0;
    double totalEfficiency = 0.0;
    int totalDeepSleep = 0;
    int totalRemSleep = 0;
    int totalLightSleep = 0;
    int totalAwake = 0;
    
    for (final data in sleepData) {
      totalDuration += data.sleepDurationMinutes;
      totalEfficiency += data.sleepEfficiency;
      totalDeepSleep += data.deepSleepMinutes;
      totalRemSleep += data.remSleepMinutes;
      totalLightSleep += data.lightSleepMinutes;
      totalAwake += data.awakeMinutes;
    }
    
    final count = sleepData.length;
    
    return {
      'averageDuration': totalDuration / count,
      'averageEfficiency': totalEfficiency / count,
      'averageDeepSleep': totalDeepSleep / count,
      'averageRemSleep': totalRemSleep / count,
      'averageLightSleep': totalLightSleep / count,
      'averageAwake': totalAwake / count,
    };
  }
  
  static double calculateSleepScore(SleepDataModel sleepData) {
    // Ideal sleep duration is around 7-9 hours (420-540 minutes)
    double durationScore = 0;
    if (sleepData.sleepDurationMinutes >= 420 && sleepData.sleepDurationMinutes <= 540) {
      durationScore = 40; // Full score for ideal duration
    } else if (sleepData.sleepDurationMinutes < 420) {
      // Partial score for shorter sleep
      durationScore = (sleepData.sleepDurationMinutes / 420) * 40;
    } else {
      // Partial score for longer sleep (diminishing returns)
      durationScore = 40 - ((sleepData.sleepDurationMinutes - 540) / 180) * 10;
      durationScore = durationScore < 30 ? 30 : durationScore; // Floor at 30
    }
    
    // Efficiency score (0-30)
    double efficiencyScore = sleepData.sleepEfficiency * 30;
    
    // Sleep stages score (0-30)
    // Ideal: ~25% deep sleep, ~20% REM sleep
    double deepSleepRatio = sleepData.deepSleepMinutes / sleepData.sleepDurationMinutes;
    double remSleepRatio = sleepData.remSleepMinutes / sleepData.sleepDurationMinutes;
    
    double deepSleepScore = 15 - (((deepSleepRatio - 0.25).abs()) / 0.25) * 15;
    deepSleepScore = deepSleepScore < 0 ? 0 : deepSleepScore;
    
    double remSleepScore = 15 - (((remSleepRatio - 0.20).abs()) / 0.20) * 15;
    remSleepScore = remSleepScore < 0 ? 0 : remSleepScore;
    
    double stagesScore = deepSleepScore + remSleepScore;
    
    // Total score
    double totalScore = durationScore + efficiencyScore + stagesScore;
    return totalScore > 100 ? 100 : totalScore;
  }
} 