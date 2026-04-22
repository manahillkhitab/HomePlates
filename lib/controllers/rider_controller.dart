import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/user_model.dart';
import '../data/local/services/order_local_service.dart';
import '../data/local/services/notification_service.dart';
import '../utils/constants.dart';

class RiderController extends ChangeNotifier {
  final OrderLocalService _orderService = OrderLocalService();
  final NotificationService _notificationService = NotificationService();

  // Load orders with status = ready
  List<OrderModel> getAvailableOrders() {
    final box = Hive.box<OrderModel>(AppConstants.orderBox);
    return box.values
        .where((order) => order.status == OrderStatus.ready)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Load orders with status = pickedUp (active deliveries)
  // In a real app, we would filter by riderId too.
  List<OrderModel> getActiveOrders() {
    final box = Hive.box<OrderModel>(AppConstants.orderBox);
    return box.values
        .where((order) => order.status == OrderStatus.pickedUp)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Load orders with status = delivered (history)
  List<OrderModel> getHistoryOrders() {
    final box = Hive.box<OrderModel>(AppConstants.orderBox);
    return box.values
        .where((order) => order.status == OrderStatus.delivered)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Pick up an order
  Future<bool> pickUpOrder(OrderModel order, UserModel rider) async {
    if (rider.role != UserRole.rider) {
      debugPrint('Error: Only riders can pick up orders');
      return false;
    }

    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.pickedUp);
      _notificationService.showStatusNotification('Delivery Started', 'You picked up ${order.dishName}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error picking up order: $e');
      return false;
    }
  }

  // Mark order as delivered
  Future<bool> completeDelivery(OrderModel order, UserModel rider) async {
    if (rider.role != UserRole.rider) {
      debugPrint('Error: Only riders can complete deliveries');
      return false;
    }

    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.delivered);
      _notificationService.showStatusNotification('Delivery Complete', 'Great job! ${order.dishName} delivered.');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing delivery: $e');
      return false;
    }
  }

  // Helper for ValueListenableBuilder (reactive UI)
  ValueListenable<Box<OrderModel>> watchOrders() {
    return _orderService.watchOrders();
  }
}
