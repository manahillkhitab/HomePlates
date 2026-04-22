import 'package:hive/hive.dart';

part 'promo_model.g.dart';

@HiveType(typeId: 20)
class PromoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code; // e.g., 'WELCOME10'

  @HiveField(2)
  final double discountPercentage; // e.g., 0.1 for 10%

  @HiveField(3)
  final double maxDiscount;

  @HiveField(4)
  final double minOrderAmount;

  @HiveField(5)
  final DateTime expiryDate;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final int usageLimit;

  @HiveField(8)
  final int usedCount;

  PromoModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    this.maxDiscount = 500,
    this.minOrderAmount = 0,
    required this.expiryDate,
    this.isActive = true,
    this.usageLimit = 100,
    this.usedCount = 0,
  });

  PromoModel copyWith({
    String? id,
    String? code,
    double? discountPercentage,
    double? maxDiscount,
    double? minOrderAmount,
    DateTime? expiryDate,
    bool? isActive,
    int? usageLimit,
    int? usedCount,
  }) {
    return PromoModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
    );
  }
}
