import 'package:hive/hive.dart';

part 'post_model.g.dart';

@HiveType(typeId: 24)
class PostModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chefId;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final String caption;

  @HiveField(4)
  final int likes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? chefName;

  @HiveField(7)
  final String? chefProfileImage;

  PostModel({
    required this.id,
    required this.chefId,
    required this.imageUrl,
    required this.caption,
    this.likes = 0,
    required this.createdAt,
    this.chefName,
    this.chefProfileImage,
  });

  PostModel copyWith({
    String? id,
    String? chefId,
    String? imageUrl,
    String? caption,
    int? likes,
    DateTime? createdAt,
    String? chefName,
    String? chefProfileImage,
  }) {
    return PostModel(
      id: id ?? this.id,
      chefId: chefId ?? this.chefId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      chefName: chefName ?? this.chefName,
      chefProfileImage: chefProfileImage ?? this.chefProfileImage,
    );
  }
}
