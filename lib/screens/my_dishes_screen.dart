import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controllers/dish_controller.dart';
import '../controllers/auth_controller.dart';
import '../data/local/models/dish_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'add_dish_screen.dart';

class MyDishesScreen extends StatefulWidget {
  const MyDishesScreen({super.key});

  @override
  State<MyDishesScreen> createState() => _MyDishesScreenState();
}

class _MyDishesScreenState extends State<MyDishesScreen> {
  late final DishController _dishController;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _dishController = DishController();
    _authController = AuthController();
    
    // Run migration to fix old dish IDs (one-time fix)
    _runMigration();
    
    // Debug: Print current user info
    debugPrint('=== MyDishesScreen initState ===');
    debugPrint('Current user: ${_authController.currentUser?.name}');
    debugPrint('Current user ID: ${_authController.currentUser?.id}');
  }

  Future<void> _runMigration() async {
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    final currentUser = _authController.currentUser;
    
    if (currentUser == null || dishBox.isEmpty) return;
    
    debugPrint('=== Running Dish Migration ===');
    
    // Only update dishes with OLD timestamp-based IDs
    // New format: "name_role" (e.g., "misha_chef")
    // Old format: "1766900608827" (timestamp)
    for (var key in dishBox.keys) {
      final dish = dishBox.get(key);
      if (dish != null) {
        // Check if chefId is a timestamp (all digits) - OLD format
        final isOldFormat = RegExp(r'^\d+$').hasMatch(dish.chefId);
        
        if (isOldFormat && dish.chefId != currentUser.id) {
          debugPrint('Migrating dish: ${dish.name} from OLD ID ${dish.chefId} to ${currentUser.id}');
          final updated = dish.copyWith(chefId: currentUser.id);
          await dishBox.put(key, updated);
        } else {
          debugPrint('Skipping dish: ${dish.name} - already has valid chef ID: ${dish.chefId}');
        }
      }
    }
    
    debugPrint('=== Migration Complete ===');
  }

  List<DishModel> _getChefDishes() {
    debugPrint('=== _getChefDishes called ===');
    
    if (_authController.currentUser == null) {
      debugPrint('No current user found!');
      return [];
    }
    
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    debugPrint('Dish box is open: ${dishBox.isOpen}');
    debugPrint('Total dishes in box: ${dishBox.length}');
    debugPrint('All dish IDs in box: ${dishBox.keys.toList()}');
    
    // Print all dishes with their chefIds
    for (var dish in dishBox.values) {
      debugPrint('Dish: ${dish.name}, ChefID: ${dish.chefId}');
    }
    
    final currentChefId = _authController.currentUser!.id;
    debugPrint('Looking for dishes with chefId: $currentChefId');
    
    final filteredDishes = dishBox.values
        .where((dish) => dish.chefId == currentChefId)
        .toList();
    
    debugPrint('Found ${filteredDishes.length} dishes for this chef');
    
    return filteredDishes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('My Dishes'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<DishModel>(AppConstants.dishBox).listenable(),
        builder: (context, Box<DishModel> box, _) {
          final dishes = _getChefDishes();
          
          if (dishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: AppTheme.mutedSaffron.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No dishes yet',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first dish to get started!',
                    style: Theme.of(context).textTheme.bodyMedium,
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
              return Card(
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
                            ? Builder(
                                builder: (context) {
                                  // Debug: Print the image path
                                  debugPrint('Loading image from: ${dish.imagePath}');
                                  debugPrint('File exists: ${File(dish.imagePath).existsSync()}');
                                  
                                  return Image.file(
                                    File(dish.imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading image: $error');
                                      debugPrint('StackTrace: $stackTrace');
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image, size: 50, color: Colors.red),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Image not found',
                                            style: TextStyle(fontSize: 10, color: Colors.red),
                                          ),
                                        ],
                                      );
                                    },
                                  );
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                dish.isAvailable ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: dish.isAvailable ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dish.isAvailable ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dish.isAvailable ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDishScreen()),
          );
        },
        backgroundColor: AppTheme.mutedSaffron,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
    );
  }
}
