// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_option.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DishOptionAdapter extends TypeAdapter<DishOption> {
  @override
  final int typeId = 22;

  @override
  DishOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DishOption(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      isSelected: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DishOption obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.isSelected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
