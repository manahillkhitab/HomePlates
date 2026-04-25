import 'package:hive/hive.dart';
import 'enums.dart';
import 'order_item.dart';

part 'order_model.g.dart';

@HiveType(typeId: 5)
enum OrderStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  accepted,

  @HiveField(2)
  cooking,

  @HiveField(3)
  ready,

  @HiveField(4)
  pickedUp,

  @HiveField(5)
  delivered,

  @HiveField(6)
  rejected,

  @HiveField(7)
  canceled,

  @HiveField(8)
  completed,
}

@HiveType(typeId: 6)
class OrderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String chefId;

  @HiveField(3)
  final String dishId;

  @HiveField(4)
  final String dishName;

  @HiveField(5)
  final String dishImagePath;

  @HiveField(6)
  final int quantity;

  @HiveField(7)
  final double pricePerItem;

  @HiveField(8)
  final double totalPrice;

  @HiveField(9)
  final OrderStatus status;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final bool isSynced;

  @HiveField(12)
  final List<OrderItem> items;

  @HiveField(13)
  final DateTime? scheduledTime;

  @HiveField(14)
  final PaymentMethod paymentMethod;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final String deliveryAddress;

  @HiveField(17)
  final String chefName;

  @HiveField(18)
  final String chefAddress;

  @HiveField(19)
  final String chefPhone;

  @HiveField(20)
  final String customerName;

  @HiveField(21)
  final String customerPhone;

  @HiveField(22)
  final String? riderId;

  @HiveField(23)
  final String? cancelReason;

  @HiveField(24)
  final RefundStatus? refundStatus;

  @HiveField(25)
  final DateTime updatedAt;

  @HiveField(26)
  final double deliveryFee;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.chefId,
    required this.dishId,
    required this.dishName,
    required this.dishImagePath,
    required this.quantity,
    required this.pricePerItem,
    required this.totalPrice,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.isSynced = false,
    this.items = const [],
    this.scheduledTime,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.notes,
    this.deliveryAddress = '',
    this.chefName = '',
    this.chefAddress = '',
    this.chefPhone = '',
    this.customerName = '',
    this.customerPhone = '',
    this.riderId,
    this.cancelReason,
    this.refundStatus,
    DateTime? updatedAt,
    this.deliveryFee = 0.0,
  }) : this.updatedAt = updatedAt ?? DateTime.now();

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? chefId,
    String? dishId,
    String? dishName,
    String? dishImagePath,
    int? quantity,
    double? pricePerItem,
    double? totalPrice,
    OrderStatus? status,
    DateTime? createdAt,
    bool? isSynced,
    List<OrderItem>? items,
    DateTime? scheduledTime,
    PaymentMethod? paymentMethod,
    String? notes,
    String? deliveryAddress,
    String? chefName,
    String? chefAddress,
    String? chefPhone,
    String? customerName,
    String? customerPhone,
    String? riderId,
    String? cancelReason,
    RefundStatus? refundStatus,
    DateTime? updatedAt,
    double? deliveryFee,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      chefId: chefId ?? this.chefId,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      dishImagePath: dishImagePath ?? this.dishImagePath,
      quantity: quantity ?? this.quantity,
      pricePerItem: pricePerItem ?? this.pricePerItem,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      items: items ?? this.items,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      chefName: chefName ?? this.chefName,
      chefAddress: chefAddress ?? this.chefAddress,
      chefPhone: chefPhone ?? this.chefPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      riderId: riderId ?? this.riderId,
      cancelReason: cancelReason ?? this.cancelReason,
      refundStatus: refundStatus ?? this.refundStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}
