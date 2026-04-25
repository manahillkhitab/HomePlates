// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      isSynced: fields[11] as bool,
      items: (fields[12] as List).cast<OrderItem>(),
      scheduledTime: fields[13] as DateTime?,
      paymentMethod: fields[14] as PaymentMethod,
      notes: fields[15] as String?,
      deliveryAddress: fields[16] as String,
      chefName: fields[17] as String,
      chefAddress: fields[18] as String,
      chefPhone: fields[19] as String,
      customerName: fields[20] as String,
      customerPhone: fields[21] as String,
      riderId: fields[22] as String?,
      cancelReason: fields[23] as String?,
      refundStatus: fields[24] as RefundStatus?,
      updatedAt: fields[25] as DateTime?,
      deliveryFee: fields[26] as double,
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
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.scheduledTime)
      ..writeByte(14)
      ..write(obj.paymentMethod)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.deliveryAddress)
      ..writeByte(17)
      ..write(obj.chefName)
      ..writeByte(18)
      ..write(obj.chefAddress)
      ..writeByte(19)
      ..write(obj.chefPhone)
      ..writeByte(20)
      ..write(obj.customerName)
      ..writeByte(21)
      ..write(obj.customerPhone)
      ..writeByte(22)
      ..write(obj.riderId)
      ..writeByte(23)
      ..write(obj.cancelReason)
      ..writeByte(24)
      ..write(obj.refundStatus)
      ..writeByte(25)
      ..write(obj.updatedAt)
      ..writeByte(26)
      ..write(obj.deliveryFee);
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
      case 8:
        return OrderStatus.completed;
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
      case OrderStatus.completed:
        writer.writeByte(8);
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
