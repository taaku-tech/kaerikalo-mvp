// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyGoalAdapter extends TypeAdapter<DailyGoal> {
  @override
  final int typeId = 10;

  @override
  DailyGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyGoal(
      date: fields[0] as DateTime,
      targetKcal: fields[1] as int,
      source: fields[2] as GoalSource,
      foodPresetId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.targetKcal)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.foodPresetId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalSourceAdapter extends TypeAdapter<GoalSource> {
  @override
  final int typeId = 1;

  @override
  GoalSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalSource.food;
      case 1:
        return GoalSource.custom;
      default:
        return GoalSource.food;
    }
  }

  @override
  void write(BinaryWriter writer, GoalSource obj) {
    switch (obj) {
      case GoalSource.food:
        writer.writeByte(0);
        break;
      case GoalSource.custom:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
