import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 20)
enum PaymentMethod {
  @HiveField(0)
  cashOnDelivery,
  @HiveField(1)
  wallet,
  @HiveField(2)
  card,
}

@HiveType(typeId: 21)
enum RefundStatus {
  @HiveField(0)
  none,
  @HiveField(1)
  partial,
  @HiveField(2)
  full,
}
