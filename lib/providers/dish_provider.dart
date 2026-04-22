import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/local/models/dish_model.dart';
import '../data/local/models/dish_option.dart';
import '../data/local/services/dish_local_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/services/sync_service.dart';

final dishProvider = AsyncNotifierProvider<DishNotifier, List<DishModel>>(DishNotifier.new);
final likedDishesProvider = AsyncNotifierProvider<LikedDishesNotifier, Set<String>>(LikedDishesNotifier.new);

class DishNotifier extends AsyncNotifier<List<DishModel>> {
  final DishLocalService _dishService = DishLocalService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<List<DishModel>> build() async {
    // Load ALL dishes from Supabase for Customer view
    try {
      final response = await Supabase.instance.client
          .from('dishes')
          .select()
          .order('created_at', ascending: false);
      
      final dishes = (response as List).map((e) => DishModel.fromJson(e)).toList();
      return dishes;
    } catch (e) {
      debugPrint('Error fetching dishes from Supabase: $e');
      // Fallback to local
      return _dishService.getAllDishes();
    }
  }

  // Manually update like count in state
  void updateDishLikeCount(String dishId, int delta) {
    if (state.value == null) return;
    
    final updatedList = state.value!.map((dish) {
      if (dish.id == dishId) {
        return dish.copyWith(likesCount: dish.likesCount + delta);
      }
      return dish;
    }).toList();
    
    state = AsyncValue.data(updatedList);
  }

  Future<void> loadDishesForChef(String chefId) async {
    state = const AsyncValue.loading();
    try {
      await SyncService().syncAll(); 
      final response = await Supabase.instance.client
          .from('dishes')
          .select()
          .eq('chef_id', chefId)
          .order('created_at', ascending: false);

      final dishes = (response as List).map((e) => DishModel.fromJson(e)).toList();
      state = AsyncValue.data(dishes);
    } catch (e, st) {
      debugPrint('Error fetching chef dishes: $e');
      // Fallback
      final localDishes = _dishService.getDishesForChef(chefId);
      if (localDishes.isNotEmpty) {
        state = AsyncValue.data(localDishes);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Copy image to app directory and return the new path
  Future<String?> saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dishImagesDir = Directory('${directory.path}/dish_images');
      
      if (!await dishImagesDir.exists()) {
        await dishImagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final newPath = '${dishImagesDir.path}/$fileName';
      
      final savedImage = await imageFile.copy(newPath);
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  // Add a new dish
  // Add a new dish
  Future<bool> addDish({
    required String chefId,
    required String name,
    required String description,
    required double price,
    required String imagePath,
    required bool isAvailable,
    required List<DishOption> options,
    required String category,
    int prepTimeMinutes = 20,
    bool isPromoted = false, // Added parameter
  }) async {
    try {
      final dishId = DateTime.now().millisecondsSinceEpoch.toString();
      final newDish = DishModel(
        id: dishId,
        chefId: chefId,
        name: name,
        description: description,
        price: price,
        imagePath: imagePath,
        isAvailable: isAvailable,
        updatedAt: DateTime.now(),
        options: options,
        category: category,
        prepTimeMinutes: prepTimeMinutes,
        likesCount: 0,
        isPromoted: isPromoted, // Pass it here
      );
        
      final response = await Supabase.instance.client
          .from('dishes')
          .insert(newDish.toJson())
          .select()
          .single();
          
      final createdDish = DishModel.fromJson(response);
      
      // Save to local Hive as well
      await _dishService.addDish(createdDish);
      
      await loadDishesForChef(chefId); 
      return true;
    } catch (e) {
        debugPrint('Error adding dish to Supabase: $e');
        return false; 
    }
  }

  // Toggle dish availability
  Future<void> toggleAvailability(String dishId, String chefId) async {
    // Optimistic local update
    await _dishService.toggleAvailability(dishId);
    
    // Remote update
    try {
       final localDish = _dishService.getDish(dishId);
       if (localDish != null) {
         await Supabase.instance.client
             .from('dishes')
             .update({'is_active': localDish.isAvailable})
             .eq('id', dishId);
       }
    } catch (e) {
      debugPrint('Error syncing toggle: $e');
    }

    await loadDishesForChef(chefId);
  }

  // Delete dish
  Future<void> deleteDish(String dishId, String chefId) async {
    try {
      await Supabase.instance.client.from('dishes').delete().eq('id', dishId);
    } catch(e) {
      debugPrint("Error deleting from Supabase: $e");
    }
    await _dishService.deleteDish(dishId);
    await loadDishesForChef(chefId);
  }
}

class LikedDishesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    return _fetchLikes();
  }

  Future<Set<String>> _fetchLikes() async {
    try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return {};
        
        final response = await Supabase.instance.client
            .from('dish_likes')
            .select('dish_id')
            .eq('user_id', userId);
            
        return (response as List).map((e) => e['dish_id'] as String).toSet();
    } catch(e) {
        debugPrint('Error fetching liked dishes: $e');
        return {};
    }
  }

  Future<void> toggleLike(String dishId) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final currentLikes = state.value ?? {};
      final isLiked = currentLikes.contains(dishId);
      
      // Optimistic update
      if (isLiked) {
          state = AsyncValue.data({...currentLikes}..remove(dishId));
      } else {
          state = AsyncValue.data({...currentLikes}..add(dishId));
      }
      
      try {
          if (isLiked) {
             await Supabase.instance.client
                 .from('dish_likes')
                 .delete()
                 .eq('dish_id', dishId)
                 .eq('user_id', userId);
          } else {
             await Supabase.instance.client
                 .from('dish_likes')
                 .insert({'dish_id': dishId, 'user_id': userId});
          }
          
          ref.read(dishProvider.notifier).updateDishLikeCount(dishId, isLiked ? -1 : 1);
          
      } catch (e) {
          debugPrint('Error toggling like: $e');
          // Revert if failed
          state = AsyncValue.data(currentLikes);
      }
  }
}
