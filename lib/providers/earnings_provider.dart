import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/order_model.dart';
import '../data/local/services/order_local_service.dart';
import '../data/local/models/user_model.dart';
import '../utils/constants.dart';

import '../providers/auth_provider.dart';

// Provider to get all delivered orders for a specific chef
final chefEarningsProvider = Provider.family<List<OrderModel>, String>((ref, chefId) {
  final allOrders = ref.watch(allOrdersStreamProvider);
  return allOrders.value
      ?.where((order) => order.chefId == chefId && order.status == OrderStatus.delivered)
      .toList() ?? [];
});

// Provider to get all delivered orders for a specific rider
final riderEarningsProvider = Provider.family<List<OrderModel>, String>((ref, riderId) {
  final allOrders = ref.watch(allOrdersStreamProvider);
  return allOrders.value
      ?.where((order) => order.riderId == riderId && order.status == OrderStatus.delivered)
      .toList() ?? [];
});

// Stream provider to watch all orders from Hive
final allOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) async* {
  final box = Hive.box<OrderModel>(AppConstants.orderBox);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

// Earnings State Class
class EarningsState {
  final double totalEarnings; // Gross before commission
  final int totalOrders;
  final double netEarnings;   // Amount user actually gets
  final double commission;

  EarningsState({
    required this.totalEarnings,
    required this.totalOrders,
    required this.netEarnings,
    required this.commission,
  });

  factory EarningsState.empty() {
    return EarningsState(
      totalEarnings: 0, 
      totalOrders: 0, 
      netEarnings: 0, 
      commission: 0
    );
  }
}

// Stats Provider
final earningsStatsProvider = Provider.family<EarningsState, String>((ref, userId) {
  final user = ref.watch(authProvider).value;
  if (user == null) return EarningsState.empty();

  if (user.role == UserRole.rider) {
    final orders = ref.watch(riderEarningsProvider(userId));
    // Riders earn a fixed Rs. 50 per delivery as per current logic
    final totalEarnings = orders.length * 50.0;
    return EarningsState(
      totalEarnings: totalEarnings,
      totalOrders: orders.length,
      netEarnings: totalEarnings,
      commission: 0.0,
    );
  } else {
    // Default to Chef logic
    final orders = ref.watch(chefEarningsProvider(userId));
    
    // Total price is what customer paid. Chef gets (Total - Delivery Fee)
    final totalEarnings = orders.fold(0.0, (sum, order) {
      double chefShare = order.totalPrice - order.deliveryFee;
      return sum + (chefShare > 0 ? chefShare : 0);
    });
    
    final commission = totalEarnings * 0.20;
    final netEarnings = totalEarnings - commission;

    return EarningsState(
      totalEarnings: totalEarnings,
      totalOrders: orders.length,
      netEarnings: netEarnings,
      commission: commission,
    );
  }
});
