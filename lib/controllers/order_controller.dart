import 'package:flutter/material.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/dish_model.dart';
import '../data/local/services/order_local_service.dart';
import '../data/local/services/notification_service.dart';
import '../data/local/models/user_model.dart';

class OrderController extends ChangeNotifier {
  final OrderLocalService _orderService = OrderLocalService();
  final NotificationService _notificationService = NotificationService();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  // Create order with quantity safety rule (≥ 1)
  Future<bool> createOrder({
    required String customerId,
    required DishModel dish,
    required int quantity,
  }) async {
    try {
      // Quantity safety rule
      if (quantity < 1) {
        debugPrint('Error: Quantity must be at least 1');
        return false;
      }

      final pricePerItem = dish.price;
      final totalPrice = pricePerItem * quantity;

      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId,
        chefId: dish.chefId,
        dishId: dish.id,
        dishName: dish.name,
        dishImagePath: dish.imagePath,
        quantity: quantity,
        pricePerItem: pricePerItem,
        totalPrice: totalPrice,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      await _orderService.createOrder(order);
      debugPrint('Order created successfully: ${order.id}');
      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return false;
    }
  }

  // Load orders for a specific customer
  void loadOrdersForCustomer(String customerId) {
    _orders = _orderService.getOrdersForCustomer(customerId);
    notifyListeners();
  }

  // Load orders for a specific chef
  void loadOrdersForChef(String chefId) {
    _orders = _orderService.getOrdersForChef(chefId);
    notifyListeners();
  }
  
  // Update order status with strict role validation
  Future<bool> updateOrderStatus({
    required OrderModel order,
    required OrderStatus newStatus,
    required UserModel currentUser,
    String? cancelReason,
    RefundStatus? refundStatus,
  }) async {
    // 1. Validate Role & Ownership
    if (!_canUpdateStatus(currentUser, order, newStatus)) {
      debugPrint('Error: Unauthorized status update attempt by ${currentUser.role.name}');
      return false;
    }

    // 2. Update in Hive
    await _orderService.updateOrderStatus(
      order.id, 
      newStatus,
      cancelReason: cancelReason,
      refundStatus: refundStatus,
    );
    
    // 3. Trigger Notification
    _triggerNotification(newStatus);

    notifyListeners();
    return true;
  }

  bool _canUpdateStatus(UserModel user, OrderModel order, OrderStatus newStatus) {
    // Terminal states check
    if (order.status == OrderStatus.delivered || 
        order.status == OrderStatus.rejected || 
        order.status == OrderStatus.canceled) {
      return false; 
    }

    // 1. Validate Role & Ownership
    bool isAuthorized = false;
    switch (user.role) {
      case UserRole.chef:
        isAuthorized = order.chefId == user.id;
        break;
      case UserRole.rider:
        // Riders can pick up any ready order or update their own
        if (newStatus == OrderStatus.pickedUp && order.status == OrderStatus.ready) {
             isAuthorized = true;
        } else {
             // TODO: Check if rider owns this delivery
             isAuthorized = true; 
        }
        break;
      case UserRole.customer:
        // Customer can only cancel their own order if it's still pending
        isAuthorized = order.customerId == user.id && newStatus == OrderStatus.canceled;
        break;
      case UserRole.admin:
        isAuthorized = true;
        break;
    }

    if (!isAuthorized) return false;

    // 2. Validate Status Transitions
    switch (user.role) {
      case UserRole.chef:
        // Allowed transitions for Chef
        if (newStatus == OrderStatus.accepted && order.status == OrderStatus.pending) return true;
        if (newStatus == OrderStatus.cooking && order.status == OrderStatus.accepted) return true;
        if (newStatus == OrderStatus.ready && order.status == OrderStatus.cooking) return true;
        if (newStatus == OrderStatus.rejected && order.status == OrderStatus.pending) return true;
        return false;

      case UserRole.rider:
        // Allowed transitions for Rider
        if (newStatus == OrderStatus.pickedUp && order.status == OrderStatus.ready) return true;
        if (newStatus == OrderStatus.delivered && order.status == OrderStatus.pickedUp) return true;
        return false;

      case UserRole.customer:
        // Customer Rule: Only cancel if pending
        if (newStatus == OrderStatus.canceled && order.status == OrderStatus.pending) return true;
        return false;
      case UserRole.admin:
        // Admin can do anything
        return true;
    }
  }

  void _triggerNotification(OrderStatus status) {
    String title = 'Order Update';
    String body = '';

    switch (status) {
      case OrderStatus.accepted:
        body = 'Your order has been accepted by the chef!';
        break;
      case OrderStatus.cooking:
        body = 'Your food is being prepared.';
        break;
      case OrderStatus.ready:
        body = 'Your order is ready for pickup!';
        break;
      case OrderStatus.pickedUp:
        body = 'Your order is on the way!';
        break;
      case OrderStatus.delivered:
        body = 'Order delivered successfully. Enjoy!';
        break;
      case OrderStatus.rejected:
        body = 'Sorry, your order was rejected by the chef.';
        break;
      case OrderStatus.canceled:
        body = 'Order has been canceled.';
        break;
      default:
        return;
    }
    
    _notificationService.showStatusNotification(title, body);
  }
}
