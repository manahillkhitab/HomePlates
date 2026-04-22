import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dish_provider.dart';
import '../data/local/models/dish_model.dart';
import '../utils/app_theme.dart';
import 'add_dish_screen.dart';
import 'reviews_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyDishesScreen extends ConsumerStatefulWidget {
  const MyDishesScreen({super.key});

  @override
  ConsumerState<MyDishesScreen> createState() => _MyDishesScreenState();
}

class _MyDishesScreenState extends ConsumerState<MyDishesScreen> {

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        ref.read(dishProvider.notifier).loadDishesForChef(user.id);
        _runMigration();
      }
    });
  }

  Future<void> _runMigration() async {
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    final currentUser = ref.read(authProvider).value;
    
    if (currentUser == null || dishBox.isEmpty) return;
    
    debugPrint('=== Running Dish Migration ===');
    
    for (var key in dishBox.keys) {
      final dish = dishBox.get(key);
      if (dish != null) {
        final isOldFormat = RegExp(r'^\d+$').hasMatch(dish.chefId);
        
        if (isOldFormat && dish.chefId != currentUser.id) {
          debugPrint('Migrating dish: ${dish.name} from OLD ID ${dish.chefId} to ${currentUser.id}');
          final updated = dish.copyWith(chefId: currentUser.id);
          await dishBox.put(key, updated);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncDishes = ref.watch(dishProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              title: Text(
                'My Kitchen',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGold,
                  fontSize: 24,
                ),
              ),
              centerTitle: false,
            ),
          ),
          asyncDishes.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load dishes',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            data: (dishes) {
              if (dishes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: 0.1,
                            child: Icon(Icons.restaurant_menu_rounded, size: 120, color: AppTheme.primaryGold),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your kitchen is empty',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add your signature dishes and start serving customers!',
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dish = dishes[index];
                      return _buildDishCard(context, dish, isDark);
                    },
                    childCount: dishes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDishScreen())),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.warmCharcoal,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text('NEW DISH', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, DishModel dish, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsScreen(dish: dish))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Updated radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Bleed Image
              Hero(
                tag: 'dish_image_${dish.id}',
                child: _buildDishImage(dish.imagePath),
              ),

              // 2. Gradient Overlay for Text Readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              
              // 2.5 Delete Button (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Dish?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to remove "${dish.name}"? This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final user = ref.read(authProvider).value;
                      if (user != null) {
                        await ref.read(dishProvider.notifier).deleteDish(dish.id, user.id);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),

              // 3. Status Toggle (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () async {
                    final user = ref.read(authProvider).value;
                    if (user != null) {
                      await ref.read(dishProvider.notifier).toggleAvailability(dish.id, user.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (dish.isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dish.isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dish.isAvailable ? 'ACTIVE' : 'INACTIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Dish Info (Bottom)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dish.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                        shadows: [
                          const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${dish.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            shadows: [
                              const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 2),
                            Text(
                              '4.8', // Placeholder or real rating if available
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDishImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        // Loading builder
        placeholder: (context, url) => Container(
          color: AppTheme.primaryGold.withValues(alpha: 0.1),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold),
          ),
        ),
        // Error builder
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 30),
              SizedBox(height: 4),
              Text('Error', style: TextStyle(color: Colors.white54, fontSize: 10))
            ],
          ),
        ),
      );
    } else if (imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
           color: Colors.grey[900], 
           child: const Icon(Icons.broken_image, color: Colors.white54)
        ),
      );
    } else {
      return Container(
        color: AppTheme.primaryGold,
        child: const Icon(Icons.restaurant, size: 40, color: Colors.white),
      );
    }
  }
}
