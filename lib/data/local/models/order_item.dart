import 'package:hive/hive.dart';
import 'dish_option.dart';

part 'order_item.g.dart';

@HiveType(typeId: 26)
class OrderItem {
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
  final List<DishOption>? selectedOptions;

  OrderItem({
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imagePath,
    this.selectedOptions,
  });
}
