import '../models/dish_model.dart';
import '../models/user_model.dart';

class RecommendationService {
  static List<DishModel> getRecommendedDishes(UserModel user, List<DishModel> allDishes) {
    if (user.orderedCategories.isEmpty) {
      // If no history, return promoted dishes or top-rated ones
      return allDishes.where((d) => d.isPromoted).toList();
    }

    // Sort categories by frequency
    final sortedCategories = user.orderedCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(3).map((e) => e.key).toList();

    // Filter dishes that belong to top categories
    final list = allDishes.where((dish) => topCategories.contains(dish.category)).toList();

    // Limit to 10 recommendations
    return list.take(10).toList();
  }
}
