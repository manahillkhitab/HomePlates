import 'package:hive/hive.dart';
import 'dish_option.dart';

part 'cart_model.g.dart';

@HiveType(typeId: 15)
class CartItem extends HiveObject {
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
  final String chefId;

  @HiveField(6)
  final List<DishOption> selectedOptions;

  CartItem({
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imagePath,
    required this.chefId,
    this.selectedOptions = const [],
  });

  CartItem copyWith({
    String? dishId,
    String? name,
    double? price,
    int? quantity,
    String? imagePath,
    String? chefId,
    List<DishOption>? selectedOptions,
  }) {
    return CartItem(
      dishId: dishId ?? this.dishId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
      chefId: chefId ?? this.chefId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}
