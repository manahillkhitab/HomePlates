// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PromoModelAdapter extends TypeAdapter<PromoModel> {
  @override
  final int typeId = 27;

  @override
  PromoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PromoModel(
      id: fields[0] as String,
      code: fields[1] as String,
      discountPercentage: fields[2] as double,
      maxDiscount: fields[3] as double,
      minOrderAmount: fields[4] as double,
      expiryDate: fields[5] as DateTime,
      isActive: fields[6] as bool,
      usageLimit: fields[7] as int,
      usedCount: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PromoModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.discountPercentage)
      ..writeByte(3)
      ..write(obj.maxDiscount)
      ..writeByte(4)
      ..write(obj.minOrderAmount)
      ..writeByte(5)
      ..write(obj.expiryDate)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.usageLimit)
      ..writeByte(8)
      ..write(obj.usedCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
