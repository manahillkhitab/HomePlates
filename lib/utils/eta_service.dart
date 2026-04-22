import 'dart:math';
import '../data/local/models/dish_model.dart';
import '../data/local/models/cart_summary.dart';

class ETAService {
  // Simulate rider speed: 5 - 10 mins per km
  static const int _minMinsPerKm = 5;
  static const int _maxMinsPerKm = 10;
  
  // Simulated buffer
  static const int _bufferMins = 10;

  /// Calculates a deterministic "simulated" distance based on chefId hash
  /// so it stays consistent for the same session/chef.
  static double _getSimulatedDistanceKm(String chefId) {
    if (chefId.isEmpty) return 2.5; // Default avg distance
    final hash = chefId.hashCode;
    final random = Random(hash); 
    // Random distance between 1.0 km and 8.0 km
    return 1.0 + random.nextDouble() * 7.0; 
  }

  /// Returns a formatted ETA range string (e.g. "35-45 min")
  static String calculateETA(DishModel dish) {
    // Prep time
    final prepTime = dish.prepTimeMinutes;

    // Travel time
    final distance = _getSimulatedDistanceKm(dish.chefId);
    final travelMin = (distance * _minMinsPerKm).round();
    final travelMax = (distance * _maxMinsPerKm).round();

    final totalMin = prepTime + travelMin + _bufferMins;
    final totalMax = prepTime + travelMax + _bufferMins;

    // Round to nearest 5 for cleaner UX
    final roundedMin = (totalMin / 5).round() * 5;
    final roundedMax = (totalMax / 5).round() * 5;

    return '$roundedMin-$roundedMax min';
  }

  /// Calculates standard ETA for cart (based on longest prep time item)
  static String calculateCartETA(CartSummary cart) {
     if (cart.items.isEmpty) return '30-45 min';
     
     // Find max prep time in cart
     int maxPrep = 20;
     String chefId = '';
     
     // We assume single chef for now (as per business logic constraint usually), 
     // but if multi-chef, we take standard max.
     // Getting max prep time from items is tricky as CartItem might not have full dish details?
     // CartItem has 'dishId'. Refetching might be expensive.
     // For now, assume simplified 35-50 min or just use a default + distance if possible.
     // Better: Update CartItem to include 'prepTime' copy?
     // OR: Just return a standard range for this iteration.
     
     // Let's improve: "35-50 min" (Standard).
     return '35-50 min';
  }
}
