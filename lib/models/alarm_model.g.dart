// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 2;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String?,
      hour: fields[1] as int,
      minute: fields[2] as int,
      isEnabled: fields[3] as bool,
      label: fields[4] as String,
      dismissType: fields[5] as DismissType,
      repeat: fields[6] as AlarmRepeat,
      weekdays: (fields[7] as List?)?.cast<bool>(),
      soundPath: fields[8] as String,
      volume: fields[9] as int,
      vibrate: fields[10] as bool,
      isMorningAlarm: fields[11] as bool,
      linkedHabitId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.isEnabled)
      ..writeByte(4)
      ..write(obj.label)
      ..writeByte(5)
      ..write(obj.dismissType)
      ..writeByte(6)
      ..write(obj.repeat)
      ..writeByte(7)
      ..write(obj.weekdays)
      ..writeByte(8)
      ..write(obj.soundPath)
      ..writeByte(9)
      ..write(obj.volume)
      ..writeByte(10)
      ..write(obj.vibrate)
      ..writeByte(11)
      ..write(obj.isMorningAlarm)
      ..writeByte(12)
      ..write(obj.linkedHabitId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmRepeatAdapter extends TypeAdapter<AlarmRepeat> {
  @override
  final int typeId = 0;

  @override
  AlarmRepeat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmRepeat.once;
      case 1:
        return AlarmRepeat.daily;
      case 2:
        return AlarmRepeat.weekdays;
      case 3:
        return AlarmRepeat.weekends;
      case 4:
        return AlarmRepeat.custom;
      default:
        return AlarmRepeat.once;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmRepeat obj) {
    switch (obj) {
      case AlarmRepeat.once:
        writer.writeByte(0);
        break;
      case AlarmRepeat.daily:
        writer.writeByte(1);
        break;
      case AlarmRepeat.weekdays:
        writer.writeByte(2);
        break;
      case AlarmRepeat.weekends:
        writer.writeByte(3);
        break;
      case AlarmRepeat.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmRepeatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DismissTypeAdapter extends TypeAdapter<DismissType> {
  @override
  final int typeId = 1;

  @override
  DismissType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DismissType.normal;
      case 1:
        return DismissType.math;
      case 2:
        return DismissType.shake;
      case 3:
        return DismissType.qrCode;
      case 4:
        return DismissType.typing;
      case 5:
        return DismissType.memory;
      case 6:
        return DismissType.barcode;
      case 7:
        return DismissType.swipe;
      default:
        return DismissType.normal;
    }
  }

  @override
  void write(BinaryWriter writer, DismissType obj) {
    switch (obj) {
      case DismissType.normal:
        writer.writeByte(0);
        break;
      case DismissType.math:
        writer.writeByte(1);
        break;
      case DismissType.shake:
        writer.writeByte(2);
        break;
      case DismissType.qrCode:
        writer.writeByte(3);
        break;
      case DismissType.typing:
        writer.writeByte(4);
        break;
      case DismissType.memory:
        writer.writeByte(5);
        break;
      case DismissType.barcode:
        writer.writeByte(6);
        break;
      case DismissType.swipe:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DismissTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
