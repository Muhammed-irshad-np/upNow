import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/models/sleep_data_model.dart';
import 'dart:io';

class HiveDatabase {
  static const String alarmBox = 'alarms';
  static const String sleepDataBox = 'sleepData';
  
  static Future<void> init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);
    
    // Note: For full implementation, we need to run the following:
    // flutter pub run build_runner build
    // to generate the proper adapter classes
    
    // Open boxes
    await Hive.openBox(alarmBox);
    await Hive.openBox(sleepDataBox);
  }
  
  // Alarm operations
  static Future<void> saveAlarm(AlarmModel alarm) async {
    final box = Hive.box(alarmBox);
    await box.put(alarm.id, alarm.toJson());
  }
  
  static Future<void> deleteAlarm(String id) async {
    final box = Hive.box(alarmBox);
    await box.delete(id);
  }
  
  static List<AlarmModel> getAllAlarms() {
    final box = Hive.box(alarmBox);
    final List<AlarmModel> alarms = [];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);
          alarms.add(AlarmModel.fromJson(jsonData));
        } catch (e) {
          print('Error deserializing alarm: $e');
        }
      }
    }
    
    return alarms;
  }
  
  static AlarmModel? getAlarm(String id) {
    final box = Hive.box(alarmBox);
    final data = box.get(id);
    
    if (data != null) {
      try {
        final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);
        return AlarmModel.fromJson(jsonData);
      } catch (e) {
        print('Error deserializing alarm: $e');
      }
    }
    
    return null;
  }
  
  // Sleep data operations
  static Future<void> saveSleepData(SleepDataModel sleepData) async {
    final box = Hive.box(sleepDataBox);
    await box.put(sleepData.id, sleepData.toJson());
  }
  
  static Future<void> deleteSleepData(String id) async {
    final box = Hive.box(sleepDataBox);
    await box.delete(id);
  }
  
  static List<SleepDataModel> getAllSleepData() {
    final box = Hive.box(sleepDataBox);
    final List<SleepDataModel> sleepData = [];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);
          sleepData.add(SleepDataModel.fromJson(jsonData));
        } catch (e) {
          print('Error deserializing sleep data: $e');
        }
      }
    }
    
    return sleepData;
  }
  
  static List<SleepDataModel> getRecentSleepData(int days) {
    final allData = getAllSleepData();
    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: days));
    
    return allData
        .where((data) => data.sleepStart.isAfter(threshold))
        .toList()
        ..sort((a, b) => b.sleepStart.compareTo(a.sleepStart));
  }
  
  static SleepDataModel? getSleepData(String id) {
    final box = Hive.box(sleepDataBox);
    final data = box.get(id);
    
    if (data != null) {
      try {
        final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);
        return SleepDataModel.fromJson(jsonData);
      } catch (e) {
        print('Error deserializing sleep data: $e');
      }
    }
    
    return null;
  }
}

// Manual adapters for MVP
class _AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final id = reader.readString();
    final hour = reader.readInt();
    final minute = reader.readInt();
    final isEnabled = reader.readBool();
    final label = reader.readString();
    final dismissType = DismissType.values[reader.readInt()];
    final repeat = AlarmRepeat.values[reader.readInt()];
    final weekdays = List<bool>.from(reader.readList());
    final soundPath = reader.readString();
    final volume = reader.readInt();
    final vibrate = reader.readBool();

    return AlarmModel(
      id: id,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
      label: label,
      dismissType: dismissType,
      repeat: repeat,
      weekdays: weekdays,
      soundPath: soundPath,
      volume: volume,
      vibrate: vibrate,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.hour);
    writer.writeInt(obj.minute);
    writer.writeBool(obj.isEnabled);
    writer.writeString(obj.label);
    writer.writeInt(obj.dismissType.index);
    writer.writeInt(obj.repeat.index);
    writer.writeList(obj.weekdays);
    writer.writeString(obj.soundPath);
    writer.writeInt(obj.volume);
    writer.writeBool(obj.vibrate);
  }
}

class _SleepDataModelAdapter extends TypeAdapter<SleepDataModel> {
  @override
  final int typeId = 1;

  @override
  SleepDataModel read(BinaryReader reader) {
    final id = reader.readString();
    final sleepStart = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final sleepEnd = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final sleepDurationMinutes = reader.readInt();
    final deepSleepMinutes = reader.readInt();
    final lightSleepMinutes = reader.readInt();
    final remSleepMinutes = reader.readInt();
    final awakeMinutes = reader.readInt();
    final sleepEfficiency = reader.readDouble();
    final hasSnoreData = reader.readBool();
    final snoreDurationMinutes = reader.readInt();

    return SleepDataModel(
      id: id,
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
      sleepDurationMinutes: sleepDurationMinutes,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      awakeMinutes: awakeMinutes,
      sleepEfficiency: sleepEfficiency,
      hasSnoreData: hasSnoreData,
      snoreDurationMinutes: snoreDurationMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, SleepDataModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.sleepStart.millisecondsSinceEpoch);
    writer.writeInt(obj.sleepEnd.millisecondsSinceEpoch);
    writer.writeInt(obj.sleepDurationMinutes);
    writer.writeInt(obj.deepSleepMinutes);
    writer.writeInt(obj.lightSleepMinutes);
    writer.writeInt(obj.remSleepMinutes);
    writer.writeInt(obj.awakeMinutes);
    writer.writeDouble(obj.sleepEfficiency);
    writer.writeBool(obj.hasSnoreData);
    writer.writeInt(obj.snoreDurationMinutes);
  }
}

class _AlarmRepeatAdapter extends TypeAdapter<AlarmRepeat> {
  @override
  final int typeId = 2;

  @override
  AlarmRepeat read(BinaryReader reader) {
    return AlarmRepeat.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AlarmRepeat obj) {
    writer.writeInt(obj.index);
  }
}

class _DismissTypeAdapter extends TypeAdapter<DismissType> {
  @override
  final int typeId = 3;

  @override
  DismissType read(BinaryReader reader) {
    return DismissType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, DismissType obj) {
    writer.writeInt(obj.index);
  }
} 