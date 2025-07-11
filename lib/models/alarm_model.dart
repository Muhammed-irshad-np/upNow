import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
enum AlarmRepeat {
  @HiveField(0)
  once,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekdays,
  @HiveField(3)
  weekends,
  @HiveField(4)
  custom
}

@HiveType(typeId: 1)
enum DismissType {
  @HiveField(0)
  normal,
  @HiveField(1)
  math,
  @HiveField(2)
  shake,
  @HiveField(3)
  qrCode,
  @HiveField(4)
  typing,
  @HiveField(5)
  memory,
  @HiveField(6)
  barcode
}

@HiveType(typeId: 2)
class AlarmModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  int hour;
  
  @HiveField(2)
  int minute;
  
  @HiveField(3)
  bool isEnabled;
  
  @HiveField(4)
  String label;
  
  @HiveField(5)
  DismissType dismissType;
  
  @HiveField(6)
  AlarmRepeat repeat;
  
  @HiveField(7)
  List<bool> weekdays; // [mon, tue, wed, thu, fri, sat, sun]
  
  @HiveField(8)
  String soundPath;
  
  @HiveField(9)
  int volume;
  
  @HiveField(10)
  bool vibrate;

  AlarmModel({
    String? id,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.label = '',
    this.dismissType = DismissType.normal,
    this.repeat = AlarmRepeat.once,
    List<bool>? weekdays,
    this.soundPath = 'alarm_sound',
    this.volume = 70,
    this.vibrate = true,
  }) : id = id ?? const Uuid().v4(),
       weekdays = weekdays ?? List.filled(7, false);

  String get timeString {
    final hourDisplay = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteDisplay = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$hourDisplay:$minuteDisplay $period';
  }

  String get labelOrTimeString => label.isNotEmpty ? label : timeString;

  String get repeatString {
    switch (repeat) {
      case AlarmRepeat.once:
        return 'Once';
      case AlarmRepeat.daily:
        return 'Daily';
      case AlarmRepeat.weekdays:
        return 'Weekdays';
      case AlarmRepeat.weekends:
        return 'Weekends';
      case AlarmRepeat.custom:
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selectedDays = <String>[];
        for (int i = 0; i < 7; i++) {
          if (weekdays[i]) {
            selectedDays.add(days[i]);
          }
        }
        return selectedDays.isEmpty ? 'Once' : selectedDays.join(', ');
    }
  }

  String get dismissTypeString {
    switch (dismissType) {
      case DismissType.normal:
        return 'Normal';
      case DismissType.math:
        return 'Math Problem';
      case DismissType.shake:
        return 'Shake';
      case DismissType.qrCode:
        return 'QR Code';
      case DismissType.typing:
        return 'Type Text';
      case DismissType.memory:
        return 'Memory Game';
      case DismissType.barcode:
        return 'Scan Barcode';
    }
  }

  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? label,
    DismissType? dismissType,
    AlarmRepeat? repeat,
    List<bool>? weekdays,
    String? soundPath,
    int? volume,
    bool? vibrate,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      dismissType: dismissType ?? this.dismissType,
      repeat: repeat ?? this.repeat,
      weekdays: weekdays ?? List.from(this.weekdays),
      soundPath: soundPath ?? this.soundPath,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
    );
  }
  
  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'label': label,
      'dismissType': dismissType.index,
      'repeat': repeat.index,
      'weekdays': weekdays,
      'soundPath': soundPath,
      'volume': volume,
      'vibrate': vibrate,
    };
  }
  
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      hour: json['hour'],
      minute: json['minute'],
      isEnabled: json['isEnabled'],
      label: json['label'],
      dismissType: DismissType.values[json['dismissType']],
      repeat: AlarmRepeat.values[json['repeat']],
      weekdays: List<bool>.from(json['weekdays']),
      soundPath: json['soundPath'],
      volume: json['volume'],
      vibrate: json['vibrate'],
    );
  }

  // Get the next alarm time as a DateTime
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    
    // Create a date with today and the alarm time
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If alarm time is in the past, adjust based on repeat type
    if (alarmTime.isBefore(now)) {
      if (repeat == AlarmRepeat.once) {
        // One-time alarm: schedule for tomorrow
        alarmTime = alarmTime.add(const Duration(days: 1));
      } else if (repeat == AlarmRepeat.daily) {
        // Daily alarm: schedule for tomorrow
        alarmTime = alarmTime.add(const Duration(days: 1));
      } else if (repeat == AlarmRepeat.weekdays) {
        // Weekdays: find next weekday
        do {
          alarmTime = alarmTime.add(const Duration(days: 1));
        } while (alarmTime.weekday > 5); // Skip Saturday (6) and Sunday (7)
      } else if (repeat == AlarmRepeat.weekends) {
        // Weekends: find next weekend
        do {
          alarmTime = alarmTime.add(const Duration(days: 1));
        } while (alarmTime.weekday != 6 && alarmTime.weekday != 7); // Only Saturday (6) and Sunday (7)
      } else if (repeat == AlarmRepeat.custom && weekdays.any((day) => day)) {
        // Custom: find next enabled day
        int days = 1;
        bool foundDay = false;
        
        // Try up to 7 days
        while (days <= 7 && !foundDay) {
          final nextDay = alarmTime.add(Duration(days: days));
          final weekdayIndex = (nextDay.weekday - 1) % 7;
          
          if (weekdays[weekdayIndex]) {
            alarmTime = nextDay;
            foundDay = true;
          } else {
            days++;
          }
        }
        
        // If no day is enabled, default to tomorrow
        if (!foundDay) {
          alarmTime = alarmTime.add(const Duration(days: 1));
        }
      }
    }
    
    return alarmTime;
  }
  
  // Get a formatted string for the next alarm time (e.g., "Tomorrow at 7:00 AM")
  String get nextAlarmString {
    if (!isEnabled) {
      return 'Disabled';
    }
    
    final nextTime = getNextAlarmTime();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final formatter = DateFormat('E, MMM d'); // Format: Mon, Jan 1
    
    // Calculate days difference
    final difference = nextTime.difference(now).inDays;
    
    // Check if it's today, tomorrow, or another day
    if (nextTime.year == now.year && nextTime.month == now.month && nextTime.day == now.day) {
      return 'Today at $timeString';
    } else if (nextTime.year == tomorrow.year && nextTime.month == tomorrow.month && nextTime.day == tomorrow.day) {
      return 'Tomorrow at $timeString';
    } else {
      // Format with day name, month and date
      return '${formatter.format(nextTime)} at $timeString';
    }
  }
} 