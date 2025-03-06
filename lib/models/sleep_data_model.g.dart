// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepDataModelAdapter extends TypeAdapter<SleepDataModel> {
  @override
  final int typeId = 1;

  @override
  SleepDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepDataModel(
      id: fields[0] as String,
      sleepStart: fields[1] as DateTime,
      sleepEnd: fields[2] as DateTime,
      sleepDurationMinutes: fields[3] as int,
      deepSleepMinutes: fields[4] as int,
      lightSleepMinutes: fields[5] as int,
      remSleepMinutes: fields[6] as int,
      awakeMinutes: fields[7] as int,
      sleepEfficiency: fields[8] as double,
      hasSnoreData: fields[9] as bool,
      snoreDurationMinutes: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SleepDataModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sleepStart)
      ..writeByte(2)
      ..write(obj.sleepEnd)
      ..writeByte(3)
      ..write(obj.sleepDurationMinutes)
      ..writeByte(4)
      ..write(obj.deepSleepMinutes)
      ..writeByte(5)
      ..write(obj.lightSleepMinutes)
      ..writeByte(6)
      ..write(obj.remSleepMinutes)
      ..writeByte(7)
      ..write(obj.awakeMinutes)
      ..writeByte(8)
      ..write(obj.sleepEfficiency)
      ..writeByte(9)
      ..write(obj.hasSnoreData)
      ..writeByte(10)
      ..write(obj.snoreDurationMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
