import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/dish_model.dart';
import '../data/local/models/user_model.dart';
import '../utils/constants.dart';

/// One-time migration script to fix chef IDs in existing dishes
/// This should be run once to update old timestamp-based IDs to name-based IDs
class DishMigrationHelper {
  static Future<void> migrateChefIds() async {
    debugPrint('=== Starting Dish Migration ===');
    
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    final userBox = Hive.box<UserModel>(AppConstants.userBox);
    
    final currentUser = userBox.get('current_user');
    
    if (currentUser == null) {
      debugPrint('No current user found, skipping migration');
      return;
    }
    
    debugPrint('Current user: ${currentUser.name}, ID: ${currentUser.id}');
    debugPrint('Total dishes before migration: ${dishBox.length}');
    
    // Get all dishes
    final allDishes = dishBox.values.toList();
    
    // Update each dish's chefId to match the current user's consistent ID
    for (var dish in allDishes) {
      debugPrint('Updating dish: ${dish.name}, old chefId: ${dish.chefId}');
      
      final updatedDish = dish.copyWith(
        chefId: currentUser.id,
      );
      
      await dishBox.put(dish.id, updatedDish);
      debugPrint('Updated to new chefId: ${updatedDish.chefId}');
    }
    
    debugPrint('=== Migration Complete ===');
    debugPrint('Total dishes after migration: ${dishBox.length}');
  }
}
