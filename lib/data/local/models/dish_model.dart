import 'package:hive/hive.dart';
import 'dish_option.dart';

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

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool isPromoted;

  @HiveField(10)
  final List<DishOption> options;

  @HiveField(11)
  final String category;

  @HiveField(12)
  final int likesCount;
  
  @HiveField(13)
  final int prepTimeMinutes;

  DishModel({
    required this.id,
    required this.chefId,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.isAvailable = true,
    this.isSynced = false,
    DateTime? updatedAt,
    this.isPromoted = false,
    this.options = const [],
    this.category = 'Other',
    this.likesCount = 0,
    this.prepTimeMinutes = 20, // Default to 20 mins
  }) : this.updatedAt = updatedAt ?? DateTime.now();

  DishModel copyWith({
    String? id,
    String? chefId,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    bool? isAvailable,
    bool? isSynced,
    DateTime? updatedAt,
    bool? isPromoted,
    List<DishOption>? options,
    String? category,
    int? likesCount,
    int? prepTimeMinutes,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isPromoted: isPromoted ?? this.isPromoted,
      options: options ?? this.options,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
    );
  }

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      id: json['id'] as String,
      chefId: json['chef_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_url'] as String? ?? '',
      isAvailable: json['is_active'] as bool? ?? true,
      isSynced: true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
      isPromoted: json['is_promoted'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => DishOption.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      category: json['category'] as String? ?? 'Other',
      likesCount: json['likes_count'] as int? ?? 0,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chef_id': chefId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imagePath,
      'is_active': isAvailable,
      'updated_at': updatedAt.toIso8601String(),
      'is_promoted': isPromoted,
      'options': options.map((e) => e.toJson()).toList(),
      'category': category,
      'likes_count': likesCount,
      'prep_time_minutes': prepTimeMinutes,
    };
  }
}
