import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'sleep_data_model.g.dart';

@HiveType(typeId: 3)
class SleepDataModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime sleepStart;
  
  @HiveField(2)
  final DateTime sleepEnd;
  
  @HiveField(3)
  final int sleepDurationMinutes;
  
  @HiveField(4)
  final int deepSleepMinutes;
  
  @HiveField(5)
  final int lightSleepMinutes;
  
  @HiveField(6)
  final int remSleepMinutes;
  
  @HiveField(7)
  final int awakeMinutes;
  
  @HiveField(8)
  final double sleepEfficiency;
  
  @HiveField(9)
  final bool hasSnoreData;
  
  @HiveField(10)
  final int snoreDurationMinutes;
  
  SleepDataModel({
    String? id,
    required this.sleepStart,
    required this.sleepEnd,
    required this.sleepDurationMinutes,
    this.deepSleepMinutes = 0,
    this.lightSleepMinutes = 0,
    this.remSleepMinutes = 0,
    this.awakeMinutes = 0,
    this.sleepEfficiency = 0,
    this.hasSnoreData = false,
    this.snoreDurationMinutes = 0,
  }) : id = id ?? const Uuid().v4();
  
  double getSleepScore() {
    // Calculate a sleep score out of 100
    double score = 0;
    
    // Base score based on sleep efficiency (contributes up to 40 points)
    score += sleepEfficiency * 0.4;
    
    // Deep sleep ratio (contributes up to 30 points)
    if (sleepDurationMinutes > 0) {
      double deepSleepRatio = deepSleepMinutes / sleepDurationMinutes;
      // Optimal deep sleep is around 20-25% of total sleep
      if (deepSleepRatio >= 0.2) {
        score += 30;
      } else {
        score += (deepSleepRatio / 0.2) * 30;
      }
    }
    
    // Duration factor (contributes up to 30 points)
    // Optimal sleep duration is 7-9 hours (420-540 minutes)
    if (sleepDurationMinutes >= 420) {
      score += 30;
    } else if (sleepDurationMinutes >= 360) {
      // 6+ hours gets at least 20 points
      score += 20 + (sleepDurationMinutes - 360) / 60 * 10;
    } else {
      // Less than 6 hours - score drops rapidly
      score += (sleepDurationMinutes / 360) * 20;
    }
    
    // Deductions for awake time and snoring
    if (sleepDurationMinutes > 0) {
      // Deduct for awake time (up to 10 points)
      double awakeRatio = awakeMinutes / sleepDurationMinutes;
      score -= awakeRatio * 20;
      
      // Deduct for snoring (up to 5 points)
      if (hasSnoreData && snoreDurationMinutes > 0) {
        double snoreRatio = snoreDurationMinutes / sleepDurationMinutes;
        score -= snoreRatio * 10;
      }
    }
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }
  
  String getFormattedDate() {
    return DateFormat('EEE, MMM d').format(sleepStart);
  }
  
  String getFormattedSleepTime() {
    return '${DateFormat('h:mm a').format(sleepStart)} - ${DateFormat('h:mm a').format(sleepEnd)}';
  }
  
  String getFormattedDuration() {
    final hours = sleepDurationMinutes ~/ 60;
    final minutes = sleepDurationMinutes % 60;
    return '${hours}h ${minutes}m';
  }
  
  int get deepSleepPercentage {
    if (sleepDurationMinutes == 0) return 0;
    return ((deepSleepMinutes / sleepDurationMinutes) * 100).round();
  }
  
  int get lightSleepPercentage {
    if (sleepDurationMinutes == 0) return 0;
    return ((lightSleepMinutes / sleepDurationMinutes) * 100).round();
  }
  
  int get remSleepPercentage {
    if (sleepDurationMinutes == 0) return 0;
    return ((remSleepMinutes / sleepDurationMinutes) * 100).round();
  }
  
  int get awakePercentage {
    if (sleepDurationMinutes == 0) return 0;
    return ((awakeMinutes / sleepDurationMinutes) * 100).round();
  }

  Map<String, double> get sleepStages {
    return {
      'Deep': deepSleepMinutes / sleepDurationMinutes,
      'Light': lightSleepMinutes / sleepDurationMinutes,
      'REM': remSleepMinutes / sleepDurationMinutes,
      'Awake': awakeMinutes / sleepDurationMinutes,
    };
  }

  SleepDataModel copyWith({
    String? id,
    DateTime? sleepStart,
    DateTime? sleepEnd,
    int? sleepDurationMinutes,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    int? awakeMinutes,
    double? sleepEfficiency,
    bool? hasSnoreData,
    int? snoreDurationMinutes,
  }) {
    return SleepDataModel(
      id: id ?? this.id,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      awakeMinutes: awakeMinutes ?? this.awakeMinutes,
      sleepEfficiency: sleepEfficiency ?? this.sleepEfficiency,
      hasSnoreData: hasSnoreData ?? this.hasSnoreData,
      snoreDurationMinutes: snoreDurationMinutes ?? this.snoreDurationMinutes,
    );
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sleepStart': sleepStart.millisecondsSinceEpoch,
      'sleepEnd': sleepEnd.millisecondsSinceEpoch,
      'sleepDurationMinutes': sleepDurationMinutes,
      'deepSleepMinutes': deepSleepMinutes,
      'lightSleepMinutes': lightSleepMinutes,
      'remSleepMinutes': remSleepMinutes,
      'awakeMinutes': awakeMinutes,
      'sleepEfficiency': sleepEfficiency,
      'hasSnoreData': hasSnoreData,
      'snoreDurationMinutes': snoreDurationMinutes,
    };
  }
  
  factory SleepDataModel.fromJson(Map<String, dynamic> json) {
    return SleepDataModel(
      id: json['id'],
      sleepStart: DateTime.fromMillisecondsSinceEpoch(json['sleepStart']),
      sleepEnd: DateTime.fromMillisecondsSinceEpoch(json['sleepEnd']),
      sleepDurationMinutes: json['sleepDurationMinutes'],
      deepSleepMinutes: json['deepSleepMinutes'],
      lightSleepMinutes: json['lightSleepMinutes'],
      remSleepMinutes: json['remSleepMinutes'],
      awakeMinutes: json['awakeMinutes'],
      sleepEfficiency: json['sleepEfficiency'],
      hasSnoreData: json['hasSnoreData'],
      snoreDurationMinutes: json['snoreDurationMinutes'],
    );
  }
} 