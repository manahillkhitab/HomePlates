import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 5)
enum OrderStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  accepted,
  
  @HiveField(2)
  rejected,
  
  @HiveField(3)
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
  });

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
    );
  }
}
