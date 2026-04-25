// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 20;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cashOnDelivery;
      case 1:
        return PaymentMethod.wallet;
      case 2:
        return PaymentMethod.card;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cashOnDelivery:
        writer.writeByte(0);
        break;
      case PaymentMethod.wallet:
        writer.writeByte(1);
        break;
      case PaymentMethod.card:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RefundStatusAdapter extends TypeAdapter<RefundStatus> {
  @override
  final int typeId = 21;

  @override
  RefundStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RefundStatus.none;
      case 1:
        return RefundStatus.partial;
      case 2:
        return RefundStatus.full;
      default:
        return RefundStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, RefundStatus obj) {
    switch (obj) {
      case RefundStatus.none:
        writer.writeByte(0);
        break;
      case RefundStatus.partial:
        writer.writeByte(1);
        break;
      case RefundStatus.full:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefundStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
