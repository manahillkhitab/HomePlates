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

  // Update order status with optional reason, refund, and rider
  Future<void> updateOrderStatus(
    String orderId, 
    OrderStatus newStatus, {
    String? cancelReason,
    RefundStatus? refundStatus,
    String? riderId,
  }) async {
    final order = _orderBox.get(orderId);
    if (order != null) {
      await _orderBox.put(
        orderId, 
        order.copyWith(
          status: newStatus,
          cancelReason: cancelReason ?? order.cancelReason,
          refundStatus: refundStatus ?? order.refundStatus,
          riderId: riderId, // Use the provided riderId directly, allowing it to be null
        ),
      );
    }
  }

  // Get a specific order by ID
  OrderModel? getOrder(String orderId) {
    return _orderBox.get(orderId);
  }

  // Get available orders for riders (status: ready)
  List<OrderModel> getAvailableOrders() {
    return _orderBox.values
        .where((order) => order.status == OrderStatus.ready && (order.riderId == null || order.riderId!.isEmpty))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get active deliveries (status: pickedUp)
  List<OrderModel> getRiderActiveOrders(String riderId) {
    return _orderBox.values
        .where((order) => order.status == OrderStatus.pickedUp && order.riderId == riderId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  // Get delivery history (status: delivered)
  List<OrderModel> getRiderHistoryOrders(String riderId) {
    return _orderBox.values
        .where((order) => order.status == OrderStatus.delivered && order.riderId == riderId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Watch orders for reactive updates
  ValueListenable<Box<OrderModel>> watchOrders() {
    return _orderBox.listenable();
  }
}
