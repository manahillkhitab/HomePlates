import 'package:hive/hive.dart';
import 'dish_option.dart';

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
}

@HiveType(typeId: 8)
enum RefundStatus {
  @HiveField(0)
  none,
  @HiveField(1)
  pending,
  @HiveField(2)
  full,
  @HiveField(3)
  partial,
}

@HiveType(typeId: 17)
enum PaymentMethod {
  @HiveField(0)
  cashOnDelivery,
  @HiveField(1)
  wallet,
}

@HiveType(typeId: 14)
class OrderItem extends HiveObject {
  @HiveField(0)
  final String dishId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String? imagePath;

  @HiveField(5)
  final List<DishOption> selectedOptions;

  OrderItem({
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imagePath,
    this.selectedOptions = const [],
  });
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
  final String? cancelReason;

  @HiveField(13)
  final RefundStatus refundStatus;

  @HiveField(14)
  final String? riderId;

  @HiveField(16)
  final List<OrderItem>? items;

  @HiveField(17)
  final PaymentMethod paymentMethod;

  @HiveField(18)
  final DateTime updatedAt;

  @HiveField(19)
  final DateTime? scheduledTime;

  @HiveField(20)
  final String? notes;

  @HiveField(21)
  final String? deliveryAddress;

  @HiveField(22)
  final double deliveryFee;

  @HiveField(23)
  final String? chefName;

  @HiveField(24)
  final String? chefAddress;

  @HiveField(25)
  final String? chefPhone;

  @HiveField(26)
  final String? customerName;

  @HiveField(27)
  final String? customerPhone;

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
    DateTime? updatedAt,
    this.isSynced = false,
    this.cancelReason,
    this.refundStatus = RefundStatus.none,
    this.riderId,
    this.items,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.scheduledTime,
    this.notes,
    this.deliveryAddress,
    this.deliveryFee = 0.0,
    this.chefName,
    this.chefAddress,
    this.chefPhone,
    this.customerName,
    this.customerPhone,
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
    DateTime? updatedAt,
    bool? isSynced,
    String? cancelReason,
    RefundStatus? refundStatus,
    String? riderId,
    List<OrderItem>? items,
    PaymentMethod? paymentMethod,
    DateTime? scheduledTime,
    String? notes,
    String? deliveryAddress,
    double? deliveryFee,
    String? chefName,
    String? chefAddress,
    String? chefPhone,
    String? customerName,
    String? customerPhone,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cancelReason: cancelReason ?? this.cancelReason,
      refundStatus: refundStatus ?? this.refundStatus,
      riderId: riderId ?? this.riderId,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      chefName: chefName ?? this.chefName,
      chefAddress: chefAddress ?? this.chefAddress,
      chefPhone: chefPhone ?? this.chefPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}
