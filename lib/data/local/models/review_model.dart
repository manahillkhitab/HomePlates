import 'package:hive/hive.dart';

part 'review_model.g.dart';

@HiveType(typeId: 25)
class ReviewModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String customerName; // Adding name for realism

  @HiveField(3)
  final String chefId;

  @HiveField(4)
  final String dishId;

  @HiveField(5)
  final String orderId;

  @HiveField(6)
  final int rating;

  @HiveField(7)
  final String comment;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.chefId,
    required this.dishId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ReviewModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? chefId,
    String? dishId,
    String? orderId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      chefId: chefId ?? this.chefId,
      dishId: dishId ?? this.dishId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
