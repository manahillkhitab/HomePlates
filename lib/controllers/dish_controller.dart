import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/local/models/dish_model.dart';
import '../data/local/services/dish_local_service.dart';

class DishController extends ChangeNotifier {
  final DishLocalService _dishService = DishLocalService();
  final ImagePicker _imagePicker = ImagePicker();

  List<DishModel> _dishes = [];
  List<DishModel> get dishes => _dishes;

  DishController() {
    _loadDishes();
  }

  void _loadDishes() {
    // Will be filtered by chefId when needed
    notifyListeners();
  }

  // Load dishes for a specific chef
  void loadDishesForChef(String chefId) {
    _dishes = _dishService.getDishesForChef(chefId);
    notifyListeners();
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
      debugPrint('Starting to save image: ${imageFile.path}');
      
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('App documents directory: ${directory.path}');
      
      final dishImagesDir = Directory('${directory.path}/dish_images');
      
      // Create directory if it doesn't exist
      if (!await dishImagesDir.exists()) {
        await dishImagesDir.create(recursive: true);
        debugPrint('Created dish_images directory');
      }

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final newPath = '${dishImagesDir.path}/$fileName';
      
      debugPrint('Copying image to: $newPath');

      // Copy file to app directory
      final savedImage = await imageFile.copy(newPath);
      debugPrint('Image saved successfully: ${savedImage.path}');
      debugPrint('File exists after save: ${await savedImage.exists()}');
      
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  // Add a new dish
  Future<bool> addDish({
    required String chefId,
    required String name,
    required String description,
    required double price,
    required String imagePath,
    bool isAvailable = true,
  }) async {
    try {
      debugPrint('Adding dish with image path: $imagePath');
      
      final dish = DishModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chefId: chefId,
        name: name,
        description: description,
        price: price,
        imagePath: imagePath,
        isAvailable: isAvailable,
      );

      await _dishService.addDish(dish);
      debugPrint('Dish added to Hive successfully');
      
      loadDishesForChef(chefId);
      return true;
    } catch (e) {
      debugPrint('Error adding dish: $e');
      return false;
    }
  }

  // Toggle dish availability
  Future<void> toggleAvailability(String dishId, String chefId) async {
    await _dishService.toggleAvailability(dishId);
    loadDishesForChef(chefId);
  }

  // Delete dish
  Future<void> deleteDish(String dishId, String chefId) async {
    await _dishService.deleteDish(dishId);
    loadDishesForChef(chefId);
  }
}
