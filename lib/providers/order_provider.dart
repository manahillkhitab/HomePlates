import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/dish_model.dart';
import '../data/local/models/user_model.dart';
import '../data/local/models/enums.dart';
import '../data/local/models/order_item.dart';
import '../data/local/services/order_local_service.dart';
import '../data/local/services/notification_service.dart';
import '../data/local/models/cart_summary.dart';
import 'wallet_provider.dart';
import 'config_provider.dart';
import 'promo_provider.dart';
import 'auth_provider.dart';
import 'dish_provider.dart';
import 'cart_provider.dart';
import '../data/local/services/sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

const double kDefaultDeliveryFee = 50.0;

final orderProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(
  OrderNotifier.new,
);

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  final OrderLocalService _orderService = OrderLocalService();
  final NotificationService _notificationService = NotificationService();

  @override
  Future<List<OrderModel>> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    try {
      if (user.role == UserRole.customer) {
        return _orderService.getOrdersForCustomer(user.id);
      } else if (user.role == UserRole.chef) {
        return _orderService.getOrdersForChef(user.id);
      } else if (user.role == UserRole.rider) {
        // Riders have multiple views, default to active deliveries or empty
        return _orderService.getRiderActiveOrders(user.id);
      }
    } catch (e, st) {
      debugPrint('Error in OrderNotifier build: $e\n$st');
      rethrow; // properly propagate the error for AsyncValue.error handling
    }
    return [];
  }

  // Create order with quantity safety rule (≥ 1)
  Future<bool> createOrder({
    required String customerId,
    required DishModel dish,
    required int quantity,
  }) async {
    try {
      if (quantity < 1) {
        debugPrint('Error: Quantity must be at least 1');
        return false;
      }

      final pricePerItem = dish.price;
      final totalPrice = pricePerItem * quantity;

      final order = OrderModel(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 8)}',
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
        items: [
          OrderItem(
            dishId: dish.id,
            name: dish.name,
            price: pricePerItem,
            quantity: quantity,
            imagePath: dish.imagePath,
          ),
        ],
      );

      await _orderService.createOrder(order);

      // Update Category Preference
      await _updateCategoryPreference(customerId, dish.category);

      debugPrint('Order created successfully: ${order.id}');

      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<bool> createOrderFromCart({
    required UserModel customer,
    required CartSummary cart,
    required List<OrderItem> items,
    PaymentMethod paymentMethod = PaymentMethod.cashOnDelivery,
    String? notes,
    String? deliveryAddress,
  }) async {
    try {
      // 1. Basic Validation
      if (items.isEmpty) {
        debugPrint('Cart is empty');
        return false;
      }

      final firstItem = items.first;
      final chefId =
          cart.chefId ??
          (cart.items.isNotEmpty ? cart.items.first.chefId : null);

      if (chefId == null) {
        debugPrint('Error: Chef ID missing in cart');
        return false;
      }

      final promo = ref.read(appliedPromoProvider);
      final config = ref.read(configProvider).value;
      final double deliveryFee = config?.deliveryFee ?? kDefaultDeliveryFee;

      double finalTotal = cart.total + deliveryFee;
      if (promo != null) {
        final discount = (cart.total * promo.discountPercentage).clamp(
          0,
          promo.maxDiscount,
        );
        finalTotal = (cart.total + deliveryFee - discount).clamp(
          0,
          double.infinity,
        );
      }

      // Generate ID securely
      final orderId =
          'ORD-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 8)}';

      // Fetch Chef Details for Snapshot (Address Locking Logic)
      final chefUser = await ref
          .read(authProvider.notifier)
          .getUserById(chefId);

      // 2. Kitchen Status Check must happen BEFORE charging the customer's wallet
      if (chefUser == null || chefUser.isKitchenClosed == true) {
        debugPrint('Error: Kitchen is currently closed or chef not found');
        throw Exception('Kitchen is currently closed');
      }

      // 3. Handle Wallet Payment
      if (paymentMethod == PaymentMethod.wallet) {
        final walletNotifier = ref.read(walletProvider(customer.id).notifier);
        final success = await walletNotifier.makePayment(
          finalTotal,
          'ORD-$orderId',
        );
        if (!success) {
          debugPrint('Insufficient wallet balance');
          throw Exception('Insufficient wallet balance');
        }
      }

      final chefName = chefUser.kitchenName.isNotEmpty
          ? chefUser.kitchenName
          : chefUser.name;
      final chefAddress = chefUser.address;
      final chefPhone = chefUser.phone;

      final order = OrderModel(
        id: orderId,
        customerId: customer.id,
        chefId: chefId,
        dishId: firstItem.dishId,
        dishName: items.length > 1
            ? '${firstItem.name} + ${items.length - 1} more'
            : firstItem.name,
        dishImagePath: firstItem.imagePath ?? '',
        quantity: cart.itemCount,
        pricePerItem: firstItem.price,
        totalPrice: finalTotal,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        scheduledTime: cart.scheduledTime,
        paymentMethod: paymentMethod,
        notes: notes,
        deliveryAddress: deliveryAddress ?? customer.address,
        items: items,
        chefName: chefName,
        chefAddress: chefAddress,
        chefPhone: chefPhone,
        customerName: customer.name,
        customerPhone: customer.phone,
      );

      // 3. Save to Local DB
      await _orderService.createOrder(order);
      debugPrint('Order saved locally: ${order.id}');

      // 4. Update Category Preferences
      final dishes = ref.read(dishProvider).value ?? [];
      for (var item in cart.items) {
        // Use a safer search to avoid StateError. firstOrNull is Dart 3.0+
        final dish = dishes.where((d) => d.id == item.dishId).isEmpty
            ? null
            : dishes.firstWhere((d) => d.id == item.dishId);
        if (dish != null) {
          await _updateCategoryPreference(customer.id, dish.category);
        }
      }

      debugPrint('Order from cart created successfully: ${order.id}');

      // IF strictly the first order and referredBy exists, credit the referrer
      final previousOrders = _orderService.getOrdersForCustomer(customer.id);
      final freshCustomer =
          await ref.read(authProvider.notifier).getUserById(customer.id) ??
          customer;

      if (previousOrders.length == 1 &&
          freshCustomer.referredBy != null &&
          freshCustomer.referredBy!.isNotEmpty &&
          freshCustomer.referredBy != 'rewarded') {
        await ref
            .read(walletProvider(freshCustomer.referredBy!).notifier)
            .issueRefund(50.0, 'REF-${order.id}');
        // Mark as rewarded to prevent duplicate payouts
        await ref
            .read(authProvider.notifier)
            .updateProfile(freshCustomer.copyWith(referredBy: 'rewarded'));
      }

      // Mark promo as used
      if (promo != null) {
        await ref.read(promoProvider.notifier).markPromoUsed(promo.id);
        ref.read(appliedPromoProvider.notifier).state = null;
      }

      // 5. Finalize
      await ref.read(cartProvider.notifier).clearCart();
      debugPrint('Order placement finalized. ID: ${order.id}');

      // Proactive Sync
      SyncService().syncAll();

      return true;
    } catch (e, stack) {
      debugPrint('CRITICAL ORDER FAILURE: $e');
      debugPrint('STACK TRACE: $stack');
      rethrow;
    }
  }

  // Load orders for a specific customer
  Future<void> loadOrdersForCustomer(String userId) async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll();
      final orders = _orderService.getOrdersForCustomer(userId);

      // Enrich with dish images if missing
      final dishes = ref.read(dishProvider).value ?? [];
      final enrichedOrders = orders.map((order) {
        if (order.dishImagePath.isEmpty) {
          final dish = dishes.where((d) => d.id == order.dishId).firstOrNull;
          if (dish != null && dish.imagePath.isNotEmpty) {
            return order.copyWith(dishImagePath: dish.imagePath);
          }
        }
        return order;
      }).toList();

      state = AsyncValue.data(enrichedOrders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Load orders for a specific chef
  Future<void> loadOrdersForChef(String chefId) async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll();
      final orders = _orderService.getOrdersForChef(chefId);
      final dishes = ref.read(dishProvider).value ?? [];
      final enriched = orders.map((order) {
        if (order.dishImagePath.isEmpty) {
          final dish = dishes.firstWhereOrNull((d) => d.id == order.dishId);
          if (dish != null) {
            return order.copyWith(dishImagePath: dish.imagePath);
          }
        }
        return order;
      }).toList();
      state = AsyncValue.data(enriched);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Load available orders for riders
  Future<void> loadAvailableOrders() async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll();
      final orders = _orderService.getAvailableOrders();
      final dishes = ref.read(dishProvider).value ?? [];
      final enriched = orders.map((order) {
        if (order.dishImagePath.isEmpty) {
          final dish = dishes.firstWhereOrNull((d) => d.id == order.dishId);
          if (dish != null) {
            return order.copyWith(dishImagePath: dish.imagePath);
          }
        }
        return order;
      }).toList();
      state = AsyncValue.data(enriched);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Load active orders for riders
  Future<void> loadRiderActiveOrders(String riderId) async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll();
      final orders = _orderService.getRiderActiveOrders(riderId);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Load history for riders
  Future<void> loadRiderHistoryOrders(String riderId) async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll();
      final orders = _orderService.getRiderHistoryOrders(riderId);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Atomic claim for riders
  Future<String?> claimOrder(OrderModel order, String riderId) async {
    final error = await SyncService().claimOrder(order.id, riderId);
    if (error == null) {
      await _orderService.updateOrderStatus(
        order.id,
        OrderStatus.ready,
        riderId: riderId,
      );
      // Reload lists concurrently (fixes multiple async loads without await)
      await Future.wait([
        loadAvailableOrders(),
        loadRiderActiveOrders(riderId),
      ]);
    }
    return error;
  }

  Future<bool> unassignOrder(OrderModel order) async {
    try {
      // Set status back to ready and clear riderId ('' allows it to pass copyWith checks)
      await _orderService.updateOrderStatus(
        order.id,
        OrderStatus.ready,
        riderId: '',
      );

      // Trigger notification for customer (optional, but good for trust)
      _notificationService.showStatusNotification(
        'Delivery Update',
        'We are assigning a new rider for your order.',
        type: 'order',
        relatedId: order.id,
        targetUserId: order.customerId,
      );

      if (order.riderId != null) {
        await loadRiderActiveOrders(order.riderId!);
      }
      await loadAvailableOrders(); // Add await to fix race condition
      return true;
    } catch (e) {
      debugPrint('Error unassigning rider: $e');
      rethrow;
    }
  }

  // Update order status with strict role validation
  Future<bool> updateOrderStatus({
    required OrderModel order,
    required OrderStatus newStatus,
    required UserModel currentUser,
    String? cancelReason,
    RefundStatus? refundStatus,
    String? riderId,
  }) async {
    // 1. Validate Role & Ownership
    if (!_canUpdateStatus(currentUser, order, newStatus)) {
      debugPrint(
        'Error: Unauthorized status update attempt by ${currentUser.role.name}',
      );
      return false;
    }

    try {
      // 2. Update in Hive
      await _orderService.updateOrderStatus(
        order.id,
        newStatus,
        cancelReason: cancelReason,
        refundStatus: refundStatus,
        riderId:
            (currentUser.role == UserRole.rider &&
                    newStatus == OrderStatus.pickedUp) ||
                (currentUser.role == UserRole.admin && riderId != null)
            ? (riderId ?? currentUser.id)
            : null,
      );

      // 3. Automated Financial Rules
      final updatedOrder = _orderService.getOrder(order.id);
      final config = ref.read(configProvider).value;

      if (updatedOrder != null && config != null) {
        // RULE 1: Wallet Refund on Customer/Admin Cancellation
        if (newStatus == OrderStatus.canceled &&
            updatedOrder.paymentMethod == PaymentMethod.wallet) {
          await ref
              .read(walletProvider(updatedOrder.customerId).notifier)
              .issueRefund(updatedOrder.totalPrice, updatedOrder.id);
        }

        // RULE 2: Chef Penalty if cancelling accepted order
        if (newStatus == OrderStatus.rejected &&
            order.status != OrderStatus.pending) {
          // Chef cancelled late: Apply 10% penalty from their future earnings or current balance
          final penaltyAmount = updatedOrder.totalPrice * 0.1;
          await ref
              .read(walletProvider(updatedOrder.chefId).notifier)
              .applyPenalty(penaltyAmount, updatedOrder.id);
        }

        // RULE 3: Partial Refund orchestration
        if (refundStatus == RefundStatus.partial) {
          // For MVP: Partial is 50%. In real app, would be dynamic.
          final partialAmount = updatedOrder.totalPrice * 0.5;
          await ref
              .read(walletProvider(updatedOrder.customerId).notifier)
              .issueRefund(partialAmount, updatedOrder.id);
        }

        // RULE 4: Trigger Earnings if Delivered (Duplicate Handling via ID required in Sync)
        if (newStatus == OrderStatus.delivered) {
          final currentDeliveryFee = config.deliveryFee ?? kDefaultDeliveryFee;
          // Credit Rider (Dynamic Delivery Fee)
          if (updatedOrder.riderId != null) {
            await ref
                .read(walletProvider(updatedOrder.riderId!).notifier)
                .addEarning(currentDeliveryFee, updatedOrder.id);
          }

          // Credit Chef (Total - Delivery Fee)
          // Robust calculation: (PricePerItem * Quantity)
          // TotalPrice often includes Delivery Fee
          double chefEarnings = updatedOrder.totalPrice - currentDeliveryFee;
          if (chefEarnings < 0) chefEarnings = 0; // Safety

          await ref
              .read(walletProvider(updatedOrder.chefId).notifier)
              .addEarning(chefEarnings, updatedOrder.id);
        }
      }

      // 4. Trigger Notification
      if (updatedOrder != null) {
        _sendTargetedNotifications(newStatus, updatedOrder);
      }

      // 4. Refresh State
      // Note: In a real async notifier, we would invalidateSelf() or similar.
      // Here we manually reload based on role.
      if (currentUser.role == UserRole.chef) {
        await loadOrdersForChef(currentUser.id);
      } else if (currentUser.role == UserRole.customer) {
        await loadOrdersForCustomer(currentUser.id);
      } else if (currentUser.role == UserRole.rider) {
        // Riders are tricky because they move items between lists (Available -> Active -> History)
        // Simpler to just let the UI reload or handle it.
        // For now, let's reload the view they are likely in?
        // Actually, typically we'd reload the specific list.
        // But since we have one state, we should reload based on context.
        // IMPORTANT: This 'one provider' limit shows here.
        // For now: don't auto-reload for riders here, let UI call load.
        // OR check status to guess.
        if (newStatus == OrderStatus.pickedUp ||
            newStatus == OrderStatus.ready) {
          // Picked Up: Claiming (move from Available to Active)
          // Ready: Dropping (move from Active to Available)
          await loadRiderActiveOrders(currentUser.id);
          if (newStatus == OrderStatus.ready) await loadAvailableOrders();
        } else if (newStatus == OrderStatus.delivered) {
          await loadRiderActiveOrders(currentUser.id);
        }
      }

      // Proactive Sync to ensure cloud matches local change
      SyncService().syncAll();

      return true;
    } catch (e, st) {
      debugPrint('Error updating status: $e\n$st');
      rethrow;
    }
  }

  bool _canUpdateStatus(
    UserModel user,
    OrderModel order,
    OrderStatus newStatus,
  ) {
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.rejected ||
        order.status == OrderStatus.canceled) {
      return false;
    }

    bool isAuthorized = false;
    switch (user.role) {
      case UserRole.chef:
        isAuthorized = order.chefId == user.id;
        break;
      case UserRole.rider:
        if (newStatus == OrderStatus.pickedUp &&
            order.status == OrderStatus.ready) {
          isAuthorized =
              order.riderId == null ||
              order.riderId == '' ||
              order.riderId == user.id;
        } else {
          isAuthorized =
              order.riderId == user.id; // Strict ownership loop check
        }
        break;
      case UserRole.customer:
        // Customer can only cancel their own order if it's still pending
        isAuthorized =
            order.customerId == user.id && newStatus == OrderStatus.canceled;
        break;
      case UserRole.admin:
        isAuthorized = true;
        break;
    }

    if (!isAuthorized) return false;

    switch (user.role) {
      case UserRole.chef:
        if (newStatus == OrderStatus.accepted &&
            order.status == OrderStatus.pending) {
          return true;
        }
        if (newStatus == OrderStatus.cooking &&
            order.status == OrderStatus.accepted) {
          return true;
        }
        if (newStatus == OrderStatus.ready &&
            order.status == OrderStatus.cooking) {
          return true;
        }
        if (newStatus == OrderStatus.rejected &&
            order.status == OrderStatus.pending) {
          return true;
        }
        return false;

      case UserRole.rider:
        if (newStatus == OrderStatus.pickedUp &&
            order.status == OrderStatus.ready) {
          return true;
        }
        if (newStatus == OrderStatus.delivered &&
            order.status == OrderStatus.pickedUp) {
          return true;
        }
        return false;

      case UserRole.customer:
        // Customer Rule: Only cancel if pending
        if (newStatus == OrderStatus.canceled &&
            order.status == OrderStatus.pending) {
          return true;
        }
        return false;
      case UserRole.admin:
        // Admin can do anything
        return true;
    }
  }

  void _sendTargetedNotifications(OrderStatus status, OrderModel order) {
    // Send role-specific notifications based on order status
    switch (status) {
      case OrderStatus.accepted:
        // Notify Customer only
        _notificationService.showStatusNotification(
          'Order Accepted',
          'Your order has been accepted by the chef!',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        break;

      case OrderStatus.cooking:
        // Notify Customer only
        _notificationService.showStatusNotification(
          'Cooking Started',
          'Your food is being prepared.',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        break;

      case OrderStatus.ready:
        // Notify Customer
        _notificationService.showStatusNotification(
          'Order Ready',
          'Your order is ready for pickup!',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        break;

      case OrderStatus.pickedUp:
        // Notify Customer
        _notificationService.showStatusNotification(
          'On The Way',
          'Your order is on the way!',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        // Notify Chef
        _notificationService.showStatusNotification(
          'Order Picked Up',
          'Rider has picked up your order.',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.chefId,
        );
        break;

      case OrderStatus.delivered:
        // Notify Customer
        _notificationService.showStatusNotification(
          'Delivered',
          'Order delivered successfully. Enjoy!',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        // Notify Chef
        _notificationService.showStatusNotification(
          'Order Complete',
          'Order delivered! Payment added to your wallet.',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.chefId,
        );
        // Notify Rider if assigned
        if (order.riderId != null) {
          _notificationService.showStatusNotification(
            'Delivery Complete',
            'Delivery fee added to your wallet!',
            type: 'order',
            relatedId: order.id,
            targetUserId: order.riderId!,
          );
        }
        break;

      case OrderStatus.rejected:
        // Notify Customer only
        _notificationService.showStatusNotification(
          'Order Rejected',
          'Sorry, your order was rejected by the chef.',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.customerId,
        );
        break;

      case OrderStatus.canceled:
        // Notify Chef if order was already accepted
        _notificationService.showStatusNotification(
          'Order Canceled',
          'Customer canceled their order.',
          type: 'order',
          relatedId: order.id,
          targetUserId: order.chefId,
        );
        break;

      default:
        return;
    }
  }

  Future<void> _updateCategoryPreference(String userId, String category) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = (await authNotifier.getUserById(userId));
    if (user != null) {
      final updatedCategories = Map<String, int>.from(user.orderedCategories);
      updatedCategories[category] = (updatedCategories[category] ?? 0) + 1;
      await authNotifier.updateProfile(
        user.copyWith(orderedCategories: updatedCategories),
      );
    }
  }
}
