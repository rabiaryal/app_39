// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      date: fields[3] as DateTime,
      startTime: fields[4] as DateTime,
      endTime: fields[5] as DateTime?,
      repeatType: fields[15] as String?,
      priority: fields[16] as String?,
      category: fields[6] as String?,
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      pausedDuration: fields[11] as Duration?,
      pausedAt: fields[12] as DateTime?,
      actualStartTime: fields[13] as DateTime?,
      actualEndTime: fields[14] as DateTime?,
      ratingId: fields[17] as String?,
    ).._status = fields[10] as EventStatus?;
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj._status)
      ..writeByte(11)
      ..write(obj.pausedDuration)
      ..writeByte(12)
      ..write(obj.pausedAt)
      ..writeByte(13)
      ..write(obj.actualStartTime)
      ..writeByte(14)
      ..write(obj.actualEndTime)
      ..writeByte(15)
      ..write(obj.repeatType)
      ..writeByte(16)
      ..write(obj.priority)
      ..writeByte(17)
      ..write(obj.ratingId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventStatusAdapter extends TypeAdapter<EventStatus> {
  @override
  final int typeId = 8;

  @override
  EventStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventStatus.notStarted;
      case 1:
        return EventStatus.ongoing;
      case 2:
        return EventStatus.completed;
      default:
        return EventStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, EventStatus obj) {
    switch (obj) {
      case EventStatus.notStarted:
        writer.writeByte(0);
        break;
      case EventStatus.ongoing:
        writer.writeByte(1);
        break;
      case EventStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
