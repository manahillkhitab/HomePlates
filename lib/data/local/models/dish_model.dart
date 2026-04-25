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
  final String imagePath; // Local file path or URL

  @HiveField(6)
  final bool isAvailable;

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final String category;

  @HiveField(9)
  final List<DishOption> options;

  @HiveField(10)
  final double rating;

  @HiveField(11)
  final int reviewCount;

  @HiveField(12)
  final int likesCount;

  @HiveField(13)
  final bool isPromoted;

  @HiveField(14)
  final int prepTimeMinutes;

  @HiveField(15)
  final DateTime updatedAt;

  DishModel({
    required this.id,
    required this.chefId,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.isAvailable = true,
    this.isSynced = false,
    this.category = 'Other',
    this.options = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.likesCount = 0,
    this.isPromoted = false,
    this.prepTimeMinutes = 30,
    DateTime? updatedAt,
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
    String? category,
    List<DishOption>? options,
    double? rating,
    int? reviewCount,
    int? likesCount,
    bool? isPromoted,
    int? prepTimeMinutes,
    DateTime? updatedAt,
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
      category: category ?? this.category,
      options: options ?? this.options,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      likesCount: likesCount ?? this.likesCount,
      isPromoted: isPromoted ?? this.isPromoted,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      id: json['id'] as String,
      chefId: json['chef_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      isSynced: true,
      category: json['category'] as String? ?? 'Other',
      options:
          (json['options'] as List?)
              ?.map((e) => DishOption.fromJson(e))
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      isPromoted: json['is_promoted'] as bool? ?? false,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 30,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chef_id': chefId,
      'name': name,
      'description': description,
      'price': price,
      'image_path': imagePath,
      'is_available': isAvailable,
      'category': category,
      'options': options.map((e) => e.toJson()).toList(),
      'rating': rating,
      'review_count': reviewCount,
      'likes_count': likesCount,
      'is_promoted': isPromoted,
      'prep_time_minutes': prepTimeMinutes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
