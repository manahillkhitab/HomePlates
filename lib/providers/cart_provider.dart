import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/cart_model.dart';
import '../data/local/models/cart_summary.dart';
import '../data/local/models/dish_model.dart';
import '../data/local/models/dish_option.dart';
import '../utils/constants.dart';

final cartProvider = NotifierProvider<CartNotifier, CartSummary>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<CartSummary> {
  late Box<CartSummary> _box;

  @override
  CartSummary build() {
    _box = Hive.box<CartSummary>(AppConstants.cartBox);
    return _box.get('current_cart') ?? CartSummary(items: []);
  }

  Future<void> addToCart(
    DishModel dish,
    int quantity, {
    List<DishOption> selectedOptions = const [],
  }) async {
    final currentItems = List<CartItem>.from(state.items);

    // Check if adding from a different chef
    if (state.chefId != null &&
        state.chefId != dish.chefId &&
        state.items.isNotEmpty) {
      throw Exception(
        'You can only order from one kitchen at a time. Please clear your basket first! 🍱',
      );
    }

    final index = currentItems.indexWhere((item) => item.dishId == dish.id);
    if (index != -1) {
      // Update existing item
      currentItems[index] = currentItems[index].copyWith(
        quantity: currentItems[index].quantity + quantity,
      );
    } else {
      // Add new item
      currentItems.add(
        CartItem(
          dishId: dish.id,
          name: dish.name,
          price: dish.price,
          quantity: quantity,
          imagePath: dish.imagePath,
          chefId: dish.chefId,
          selectedOptions: selectedOptions,
        ),
      );
    }

    state = CartSummary(
      items: currentItems,
      chefId: dish.chefId,
      scheduledTime: state.scheduledTime,
    );
    await _box.put('current_cart', state);
  }

  Future<void> removeFromCart(String dishId) async {
    final currentItems = List<CartItem>.from(state.items);
    currentItems.removeWhere((item) => item.dishId == dishId);

    final newChefId = currentItems.isEmpty ? null : state.chefId;
    state = CartSummary(
      items: currentItems,
      chefId: newChefId,
      scheduledTime: state.scheduledTime,
    );
    await _box.put('current_cart', state);
  }

  Future<void> updateQuantity(String dishId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(dishId);
      return;
    }

    final currentItems = List<CartItem>.from(state.items);
    final index = currentItems.indexWhere((item) => item.dishId == dishId);

    if (index != -1) {
      currentItems[index] = currentItems[index].copyWith(quantity: quantity);
      state = CartSummary(
        items: currentItems,
        chefId: state.chefId,
        scheduledTime: state.scheduledTime,
      );
      await _box.put('current_cart', state);
    }
  }

  Future<void> clearCart() async {
    state = CartSummary(items: [], scheduledTime: null);
    await _box.put('current_cart', state);
  }

  Future<void> updateScheduledTime(DateTime? time) async {
    state = CartSummary(
      items: state.items,
      chefId: state.chefId,
      scheduledTime: time,
    );
    await _box.put('current_cart', state);
  }
}
