import 'package:hive/hive.dart';

part 'dish_model.g.dart';

@HiveType(typeId: 4)
class DishModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chefId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String imagePath; // Local file path

  @HiveField(6)
  final bool isAvailable;

  @HiveField(7)
  final bool isSynced;

  DishModel({
    required this.id,
    required this.chefId,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.isAvailable = true,
    this.isSynced = false,
  });

  DishModel copyWith({
    String? id,
    String? chefId,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    bool? isAvailable,
    bool? isSynced,
  }) {
    return DishModel(
      id: id ?? this.id,
      chefId: chefId ?? this.chefId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      isAvailable: isAvailable ?? this.isAvailable,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
