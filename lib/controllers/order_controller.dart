import 'package:flutter/material.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/dish_model.dart';
import '../data/local/services/order_local_service.dart';

class OrderController extends ChangeNotifier {
  final OrderLocalService _orderService = OrderLocalService();

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

  // Update order status (for future chef acceptance flow)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _orderService.updateOrderStatus(orderId, newStatus);
    notifyListeners();
  }
}
