import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/dish_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'dish_detail_screen.dart';

class BrowseDishesScreen extends StatelessWidget {
  const BrowseDishesScreen({super.key});

  List<DishModel> _getAvailableDishes() {
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    return dishBox.values
        .where((dish) => dish.isAvailable)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Browse Dishes'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<DishModel>(AppConstants.dishBox).listenable(),
        builder: (context, Box<DishModel> box, _) {
          final dishes = _getAvailableDishes();

          if (dishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 80,
                    color: AppTheme.mutedSaffron.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No dishes available',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for delicious homemade meals!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DishDetailScreen(dish: dish),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dish Image
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: dish.imagePath.isNotEmpty
                              ? Image.file(
                                  File(dish.imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 50);
                                  },
                                )
                              : const Icon(Icons.image, size: 50),
                        ),
                      ),
                      // Dish Info
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${dish.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.mutedSaffron,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
