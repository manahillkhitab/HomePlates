import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/order_model.dart';
import '../../../utils/constants.dart';

class OrderLocalService {
  Box<OrderModel> get _orderBox => Hive.box<OrderModel>(AppConstants.orderBox);

  // Create a new order
  Future<void> createOrder(OrderModel order) async {
    await _orderBox.put(order.id, order);
  }

  // Get all orders for a specific customer
  List<OrderModel> getOrdersForCustomer(String customerId) {
    return _orderBox.values
        .where((order) => order.customerId == customerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Latest first
  }

  // Get all orders for a specific chef (read-only for now)
  List<OrderModel> getOrdersForChef(String chefId) {
    return _orderBox.values
        .where((order) => order.chefId == chefId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Latest first
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orderBox.get(orderId);
    if (order != null) {
      await _orderBox.put(orderId, order.copyWith(status: newStatus));
    }
  }

  // Get a specific order by ID
  OrderModel? getOrder(String orderId) {
    return _orderBox.get(orderId);
  }

  // Watch orders for reactive updates
  ValueListenable<Box<OrderModel>> watchOrders() {
    return _orderBox.listenable();
  }
}
