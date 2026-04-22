import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 13)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final bool isRead;

  @HiveField(5)
  final String? type; // 'order', 'wallet', 'system'

  @HiveField(6)
  final String? relatedId; // e.g. orderId

  @HiveField(7)
  final String userId; // Owner of this notification

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.relatedId,
    required this.userId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? relatedId,
    String? userId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      userId: userId ?? this.userId,
    );
  }
}
