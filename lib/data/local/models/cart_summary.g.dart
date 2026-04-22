// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartSummaryAdapter extends TypeAdapter<CartSummary> {
  @override
  final int typeId = 23;

  @override
  CartSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartSummary(
      items: (fields[0] as List).cast<CartItem>(),
      chefId: fields[1] as String?,
      scheduledTime: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CartSummary obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.items)
      ..writeByte(1)
      ..write(obj.chefId)
      ..writeByte(2)
      ..write(obj.scheduledTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
