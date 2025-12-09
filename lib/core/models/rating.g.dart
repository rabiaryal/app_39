// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RatingAdapter extends TypeAdapter<Rating> {
  @override
  final int typeId = 6;

  @override
  Rating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rating(
      id: fields[0] as String,
      itemId: fields[1] as String,
      itemType: fields[2] as ItemType,
      rating: fields[3] as RatingValue,
      comment: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Rating obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.itemType)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.comment)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RatingValueAdapter extends TypeAdapter<RatingValue> {
  @override
  final int typeId = 11;

  @override
  RatingValue read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RatingValue.veryPoor;
      case 1:
        return RatingValue.poor;
      case 2:
        return RatingValue.average;
      case 3:
        return RatingValue.good;
      case 4:
        return RatingValue.excellent;
      default:
        return RatingValue.veryPoor;
    }
  }

  @override
  void write(BinaryWriter writer, RatingValue obj) {
    switch (obj) {
      case RatingValue.veryPoor:
        writer.writeByte(0);
        break;
      case RatingValue.poor:
        writer.writeByte(1);
        break;
      case RatingValue.average:
        writer.writeByte(2);
        break;
      case RatingValue.good:
        writer.writeByte(3);
        break;
      case RatingValue.excellent:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingValueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemTypeAdapter extends TypeAdapter<ItemType> {
  @override
  final int typeId = 12;

  @override
  ItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemType.event;
      case 1:
        return ItemType.task;
      case 2:
        return ItemType.appointment;
      case 3:
        return ItemType.note;
      case 4:
        return ItemType.transaction;
      default:
        return ItemType.event;
    }
  }

  @override
  void write(BinaryWriter writer, ItemType obj) {
    switch (obj) {
      case ItemType.event:
        writer.writeByte(0);
        break;
      case ItemType.task:
        writer.writeByte(1);
        break;
      case ItemType.appointment:
        writer.writeByte(2);
        break;
      case ItemType.note:
        writer.writeByte(3);
        break;
      case ItemType.transaction:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
