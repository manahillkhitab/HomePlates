import 'package:hive/hive.dart';

part 'dish_option.g.dart';

@HiveType(typeId: 22)
class DishOption extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final bool isSelected; // Used in UI/Order state

  DishOption({
    required this.id,
    required this.name,
    required this.price,
    this.isSelected = false,
  });

  DishOption copyWith({
    String? id,
    String? name,
    double? price,
    bool? isSelected,
  }) {
    return DishOption(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory DishOption.fromJson(Map<String, dynamic> json) {
    return DishOption(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch
              .toString(), // fallback if missing
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isSelected: json['is_selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'is_selected': isSelected};
  }
}
