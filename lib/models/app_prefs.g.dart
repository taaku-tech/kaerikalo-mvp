// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_prefs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppPrefsAdapter extends TypeAdapter<AppPrefs> {
  @override
  final int typeId = 13;

  @override
  AppPrefs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppPrefs(
      defaultTargetKcal: fields[0] as int,
      notificationsEnabled: fields[1] as bool,
      lastOpened: fields[2] as DateTime?,
      dailyHour: fields[3] as int?,
      dailyMinute: fields[4] as int?,
      weeklyWeekday: fields[5] as int?,
      weeklyHour: fields[6] as int?,
      weeklyMinute: fields[7] as int?,
      weekStartWeekday: fields[8] as int,
      migratedToHive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppPrefs obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.defaultTargetKcal)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.lastOpened)
      ..writeByte(3)
      ..write(obj.dailyHour)
      ..writeByte(4)
      ..write(obj.dailyMinute)
      ..writeByte(5)
      ..write(obj.weeklyWeekday)
      ..writeByte(6)
      ..write(obj.weeklyHour)
      ..writeByte(7)
      ..write(obj.weeklyMinute)
      ..writeByte(8)
      ..write(obj.weekStartWeekday)
      ..writeByte(9)
      ..write(obj.migratedToHive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPrefsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
