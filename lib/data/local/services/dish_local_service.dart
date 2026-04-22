import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dish_model.dart';
import '../../../utils/constants.dart';

class DishLocalService {
  Box<DishModel> get _dishBox => Hive.box<DishModel>(AppConstants.dishBox);

  // Add a new dish
  Future<void> addDish(DishModel dish) async {
    await _dishBox.put(dish.id, dish);
  }

  // Get all dishes for a specific chef
  List<DishModel> getDishesForChef(String chefId) {
    return _dishBox.values.where((dish) => dish.chefId == chefId).toList();
  }

  // Toggle dish availability
  Future<void> toggleAvailability(String dishId) async {
    final dish = _dishBox.get(dishId);
    if (dish != null) {
      await _dishBox.put(dishId, dish.copyWith(isAvailable: !dish.isAvailable));
    }
  }

  // Delete a dish
  Future<void> deleteDish(String dishId) async {
    await _dishBox.delete(dishId);
  }

  // Get a specific dish by ID
  DishModel? getDish(String dishId) {
    return _dishBox.get(dishId);
  }

  // Watch dishes for a specific chef (reactive)
  ValueListenable<Box<DishModel>> watchDishes() {
    return _dishBox.listenable();
  }
}
