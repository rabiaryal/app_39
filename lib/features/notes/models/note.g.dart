// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 2;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      date: fields[3] as DateTime,
      category: fields[4] as String?,
      tags: (fields[5] as List?)?.cast<String>(),
      isPinned: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      ratingId: fields[10] as String?,
    ).._status = fields[9] as NoteStatus?;
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj._status)
      ..writeByte(10)
      ..write(obj.ratingId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteStatusAdapter extends TypeAdapter<NoteStatus> {
  @override
  final int typeId = 9;

  @override
  NoteStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoteStatus.notStarted;
      case 1:
        return NoteStatus.active;
      case 2:
        return NoteStatus.done;
      case 3:
        return NoteStatus.urgent;
      default:
        return NoteStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, NoteStatus obj) {
    switch (obj) {
      case NoteStatus.notStarted:
        writer.writeByte(0);
        break;
      case NoteStatus.active:
        writer.writeByte(1);
        break;
      case NoteStatus.done:
        writer.writeByte(2);
        break;
      case NoteStatus.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
