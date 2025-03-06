import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

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
} 