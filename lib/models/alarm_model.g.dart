// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      isEnabled: fields[3] as bool,
      label: fields[4] as String,
      dismissType: fields[5] as DismissType,
      repeat: fields[6] as AlarmRepeat,
      weekdays: (fields[7] as List).cast<bool>(),
      soundPath: fields[8] as String,
      volume: fields[9] as int,
      vibrate: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.vibrate);
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
