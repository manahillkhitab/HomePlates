import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  customer,
  @HiveField(1)
  chef,
  @HiveField(2)
  rider,
}

@HiveType(typeId: 3)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final UserRole role;

  @HiveField(3)
  final bool isLoggedIn;

  @HiveField(4)
  final bool isSynced;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.isLoggedIn = false,
    this.isSynced = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    UserRole? role,
    bool? isLoggedIn,
    bool? isSynced,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
