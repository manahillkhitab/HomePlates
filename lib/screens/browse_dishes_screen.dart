import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/dish_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../widgets/state_wrapper.dart';
import '../widgets/skeleton_loader.dart';
import '../providers/dish_provider.dart';
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import 'dish_detail_screen.dart';
import '../providers/review_provider.dart';
import '../data/local/models/user_model.dart';
import '../utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/dish_card.dart'; // Added missing import

class BrowseDishesScreen extends ConsumerWidget {
  final bool isEmbed;
  const BrowseDishesScreen({super.key, this.isEmbed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final asyncDishes = ref.watch(dishProvider);

    return StateWrapper<List<DishModel>>(
      state: asyncDishes,
      loading: () => const SkeletonLoader.card(count: 6),
      isEmpty: (dishes) => _getFilteredDishes(dishes, ref).isEmpty,
      empty: () => EmptyState(
        icon: Icons.restaurant_menu,
        message: 'No dishes match your filters',
        actionLabel: 'Clear Filters',
        onAction: () => ref.read(categoryProvider.notifier).update('All'),
      ),
      data: (allDishes) {
        final query = ref.watch(searchQueryProvider).toLowerCase();
        final selectedCategory = ref.watch(categoryProvider);
        final usersBox = Hive.box<UserModel>(AppConstants.userBox);
        final filters = ref.watch(filterProvider);

        var dishes = allDishes.where((dish) {
          final chef = usersBox.get(dish.chefId);
          final isKitchenOpen = !(chef?.isKitchenClosed ?? false);
          
          final matchesAvailability = dish.isAvailable && isKitchenOpen;
          final matchesSearch = query.isEmpty || dish.name.toLowerCase().contains(query) || dish.description.toLowerCase().contains(query);
          final matchesCategory = selectedCategory == 'All' || dish.category == selectedCategory;
          
          // Advanced Filters
          final matchesPrice = dish.price >= filters.priceRange.start && dish.price <= filters.priceRange.end;
          final matchesRating = filters.minRating == 0.0 || (4.5 >= filters.minRating); // Using 4.5 default for now
          
          return matchesAvailability && matchesSearch && matchesCategory && matchesPrice && matchesRating;
        }).toList();

        // Sorting
        switch (filters.sortBy) {
          case 'Price: Low to High':
            dishes.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Price: High to Low':
            dishes.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'Top Rated':
            final reviewNotifier = ref.read(reviewProvider.notifier);
            dishes.sort((a, b) {
              final ratingA = reviewNotifier.getDishRating(a.id);
              final ratingB = reviewNotifier.getDishRating(b.id);
              return ratingB.compareTo(ratingA); // Descending
            });
            break;
          case 'Newest':
          default:
            dishes.sort((a, b) => b.id.compareTo(a.id));
            break;
        }
        
        return GridView.builder(
          shrinkWrap: isEmbed,
          physics: isEmbed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isEmbed ? 0 : AppSpacing.lg,
            vertical: isEmbed ? 0 : AppSpacing.lg,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.75,
          ),
          itemCount: dishes.length,
          itemBuilder: (context, index) => DishCard(dish: dishes[index]),
        );
      },
    );
  }

  List<DishModel> _getFilteredDishes(List<DishModel> allDishes, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).toLowerCase();
    final selectedCategory = ref.watch(categoryProvider);
    final usersBox = Hive.box<UserModel>(AppConstants.userBox);
    final filters = ref.watch(filterProvider);

    var dishes = allDishes.where((dish) {
      final chef = usersBox.get(dish.chefId);
      final isKitchenOpen = !(chef?.isKitchenClosed ?? false);
      
      final matchesAvailability = dish.isAvailable && isKitchenOpen;
      final matchesSearch = query.isEmpty || 
          dish.name.toLowerCase().contains(query) || 
          dish.description.toLowerCase().contains(query);
      final matchesCategory = selectedCategory == 'All' || dish.category == selectedCategory;
      
      final matchesPrice = dish.price >= filters.priceRange.start && 
          dish.price <= filters.priceRange.end;
      final matchesRating = filters.minRating == 0.0 || (4.5 >= filters.minRating);
      
      return matchesAvailability && matchesSearch && matchesCategory && 
          matchesPrice && matchesRating;
    }).toList();

    // Sorting
    switch (filters.sortBy) {
      case 'Price: Low to High':
        dishes.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        dishes.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Top Rated':
        final reviewNotifier = ref.read(reviewProvider.notifier);
        dishes.sort((a, b) {
          final ratingA = reviewNotifier.getDishRating(a.id);
          final ratingB = reviewNotifier.getDishRating(b.id);
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Newest':
      default:
        dishes.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return dishes;
  }
}

