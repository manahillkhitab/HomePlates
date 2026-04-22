// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 14;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      dishId: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      quantity: fields[3] as int,
      imagePath: fields[4] as String?,
      selectedOptions: (fields[5] as List).cast<DishOption>(),
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dishId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.selectedOptions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 6;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      chefId: fields[2] as String,
      dishId: fields[3] as String,
      dishName: fields[4] as String,
      dishImagePath: fields[5] as String,
      quantity: fields[6] as int,
      pricePerItem: fields[7] as double,
      totalPrice: fields[8] as double,
      status: fields[9] as OrderStatus,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[18] as DateTime?,
      isSynced: fields[11] as bool,
      cancelReason: fields[12] as String?,
      refundStatus: fields[13] as RefundStatus,
      riderId: fields[14] as String?,
      items: (fields[16] as List?)?.cast<OrderItem>(),
      paymentMethod: fields[17] as PaymentMethod,
      scheduledTime: fields[19] as DateTime?,
      notes: fields[20] as String?,
      deliveryAddress: fields[21] as String?,
      deliveryFee: fields[22] as double,
      chefName: fields[23] as String?,
      chefAddress: fields[24] as String?,
      chefPhone: fields[25] as String?,
      customerName: fields[26] as String?,
      customerPhone: fields[27] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.chefId)
      ..writeByte(3)
      ..write(obj.dishId)
      ..writeByte(4)
      ..write(obj.dishName)
      ..writeByte(5)
      ..write(obj.dishImagePath)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.pricePerItem)
      ..writeByte(8)
      ..write(obj.totalPrice)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.cancelReason)
      ..writeByte(13)
      ..write(obj.refundStatus)
      ..writeByte(14)
      ..write(obj.riderId)
      ..writeByte(16)
      ..write(obj.items)
      ..writeByte(17)
      ..write(obj.paymentMethod)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.scheduledTime)
      ..writeByte(20)
      ..write(obj.notes)
      ..writeByte(21)
      ..write(obj.deliveryAddress)
      ..writeByte(22)
      ..write(obj.deliveryFee)
      ..writeByte(23)
      ..write(obj.chefName)
      ..writeByte(24)
      ..write(obj.chefAddress)
      ..writeByte(25)
      ..write(obj.chefPhone)
      ..writeByte(26)
      ..write(obj.customerName)
      ..writeByte(27)
      ..write(obj.customerPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 5;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.accepted;
      case 2:
        return OrderStatus.cooking;
      case 3:
        return OrderStatus.ready;
      case 4:
        return OrderStatus.pickedUp;
      case 5:
        return OrderStatus.delivered;
      case 6:
        return OrderStatus.rejected;
      case 7:
        return OrderStatus.canceled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.pending:
        writer.writeByte(0);
        break;
      case OrderStatus.accepted:
        writer.writeByte(1);
        break;
      case OrderStatus.cooking:
        writer.writeByte(2);
        break;
      case OrderStatus.ready:
        writer.writeByte(3);
        break;
      case OrderStatus.pickedUp:
        writer.writeByte(4);
        break;
      case OrderStatus.delivered:
        writer.writeByte(5);
        break;
      case OrderStatus.rejected:
        writer.writeByte(6);
        break;
      case OrderStatus.canceled:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RefundStatusAdapter extends TypeAdapter<RefundStatus> {
  @override
  final int typeId = 8;

  @override
  RefundStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RefundStatus.none;
      case 1:
        return RefundStatus.pending;
      case 2:
        return RefundStatus.full;
      case 3:
        return RefundStatus.partial;
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
      case RefundStatus.pending:
        writer.writeByte(1);
        break;
      case RefundStatus.full:
        writer.writeByte(2);
        break;
      case RefundStatus.partial:
        writer.writeByte(3);
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

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 17;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cashOnDelivery;
      case 1:
        return PaymentMethod.wallet;
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
