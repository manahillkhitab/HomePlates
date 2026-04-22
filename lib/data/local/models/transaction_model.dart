import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 10)
enum TransactionType {
  @HiveField(0)
  earning,
  
  @HiveField(1)
  withdrawal,
  
  @HiveField(2)
  refund, // Money back to user (e.g. customer)
  
  @HiveField(3)
  penalty, // Deduction from user (e.g. chef)
  
  @HiveField(4)
  payment, // Payment for order (customer)

  @HiveField(5)
  topup // Add money to wallet (customer)
}

@HiveType(typeId: 11)
enum TransactionStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  completed,
  
  @HiveField(2)
  rejected
}

@HiveType(typeId: 12)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final TransactionType type;

  @HiveField(4)
  final TransactionStatus status;

  @HiveField(5)
  final String? orderId;

  @HiveField(6)
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.orderId,
    required this.createdAt,
    DateTime? updatedAt,
  }) : this.updatedAt = updatedAt ?? DateTime.now();

  @HiveField(7)
  final DateTime updatedAt;

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? orderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
