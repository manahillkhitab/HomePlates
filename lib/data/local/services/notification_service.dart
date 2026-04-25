import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_model.dart';
import '../../../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: iOS settings would go here

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> showStatusNotification(
    String title,
    String body, {
    String? type,
    String? relatedId,
    required String targetUserId,
  }) async {
    // 1. Save to Hive (always save, regardless of current user)
    try {
      final box = Hive.box<NotificationModel>(AppConstants.notificationBox);
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final notification = NotificationModel(
        id: notificationId,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: type,
        relatedId: relatedId,
        userId: targetUserId,
      );
      await box.put(notification.id, notification);
      debugPrint(
        'Notification saved to Hive for user $targetUserId: ${notification.id}',
      );
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }

    // 2. Show Local Notification ONLY if it's for the current device's user
    // Note: In a real multi-device scenario, we'd check against logged-in user
    // For now, we'll show it (the sync will handle cross-device delivery)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'order_status_channel',
          'Order Updates',
          channelDescription: 'Notifications for order status changes',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      final displayId = (DateTime.now().millisecondsSinceEpoch % 1000000000)
          .toInt();
      await flutterLocalNotificationsPlugin.show(
        displayId,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    final box = Hive.box<NotificationModel>(AppConstants.notificationBox);
    final notification = box.get(id);
    if (notification != null) {
      await box.put(id, notification.copyWith(isRead: true));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final box = Hive.box<NotificationModel>(AppConstants.notificationBox);
    for (var key in box.keys) {
      final notification = box.get(key);
      if (notification != null &&
          !notification.isRead &&
          notification.userId == userId) {
        await box.put(key, notification.copyWith(isRead: true));
      }
    }
  }

  Future<void> clearAll(String userId) async {
    final box = Hive.box<NotificationModel>(AppConstants.notificationBox);
    final keysToDelete = box.values
        .where((n) => n.userId == userId)
        .map((n) => n.id)
        .toList();
    await box.deleteAll(keysToDelete);
  }
}
