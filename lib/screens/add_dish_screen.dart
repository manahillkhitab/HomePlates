import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dish_provider.dart';
import '../providers/auth_provider.dart';
import '../data/local/models/dish_option.dart';
import '../utils/app_theme.dart';
import 'package:uuid/uuid.dart';

class AddDishScreen extends ConsumerStatefulWidget {
  const AddDishScreen({super.key});

  @override
  ConsumerState<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends ConsumerState<AddDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '20');
  
  File? _selectedImage;
  bool _isAvailable = true;
  bool _isPromoted = false; // Added state variable
  bool _isLoading = false;
  String _selectedCategory = 'Pakistani';
  final List<DishOption> _options = [];
  final _optionNameController = TextEditingController();
  final _optionPriceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ref.read(dishProvider.notifier).pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(dishProvider.notifier);
      
      // Save image locally
      final imagePath = await notifier.saveImageLocally(_selectedImage!);
      
      if (imagePath == null) {
        throw Exception('Failed to save image');
      }

      // Parse price
      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        throw Exception('Invalid price');
      }

      // Parse prep time
      final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 20;

      // Add dish
      final success = await notifier.addDish(
        chefId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        imagePath: imagePath,
        isAvailable: _isAvailable,
        options: _options,
        category: _selectedCategory,
        prepTimeMinutes: prepTime,
        isPromoted: _isPromoted, // Pass promoted status
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dish added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Add New Dish',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGold,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius - 2),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 48,
                                      color: AppTheme.primaryGold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Upload Dish Photo',
                                    style: GoogleFonts.outfit(
                                      color: isDark ? Colors.white70 : AppTheme.warmCharcoal.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Showcase your culinary masterpiece',
                                    style: GoogleFonts.outfit(
                                      color: isDark ? Colors.white30 : AppTheme.warmCharcoal.withValues(alpha: 0.3),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Dish Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Dish Name',
                      hint: 'What\'s cooking today?',
                      icon: Icons.restaurant_rounded,
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Please enter a dish name' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe ingredients, taste, and vibes...',
                      icon: Icons.description_rounded,
                      maxLines: 4,
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price (Rs.)',
                            hint: '0',
                            icon: Icons.sell_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              final price = double.tryParse(value.trim());
                              if (price == null || price <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _prepTimeController,
                            label: 'Prep Time (min)',
                            hint: '20',
                            icon: Icons.timer_rounded,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                               if (value == null || value.trim().isEmpty) return 'Required';
                               return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Category Selection
                    _buildSectionHeader('Category', Icons.category_rounded),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : AppTheme.warmCharcoal,
                            fontWeight: FontWeight.w600,
                          ),
                          items: ['Pakistani', 'Fast Food', 'Deserts', 'Healthy', 'Drinks', 'Other']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Options Management
                    _buildSectionHeader('Customization Options', Icons.add_circle_outline_rounded),
                    const SizedBox(height: 16),
                    ..._options.asMap().entries.map((entry) {
                       final index = entry.key;
                       final opt = entry.value;
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: isDark ? AppTheme.darkCard : Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                         ),
                         child: Row(
                           children: [
                             Expanded(child: Text(opt.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                             Text('Rs. ${opt.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppTheme.primaryGold, fontWeight: FontWeight.w900)),
                             IconButton(
                               icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                               onPressed: () => setState(() => _options.removeAt(index)),
                             ),
                           ],
                         ),
                       );
                    }).toList(),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard.withValues(alpha: 0.5) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _optionNameController,
                                  decoration: const InputDecoration(hintText: 'Option (e.g. Extra Cheese)', border: InputBorder.none),
                                  style: GoogleFonts.outfit(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _optionPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Price', border: InputBorder.none),
                                  style: GoogleFonts.outfit(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_box_rounded, color: AppTheme.primaryGold, size: 32),
                                onPressed: () {
                                  final name = _optionNameController.text.trim();
                                  final price = double.tryParse(_optionPriceController.text.trim());
                                  if (name.isNotEmpty && price != null) {
                                    setState(() {
                                      _options.add(DishOption(id: const Uuid().v4(), name: name, price: price));
                                      _optionNameController.clear();
                                      _optionPriceController.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Availability Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_rounded, 
                            color: _isAvailable ? AppTheme.primaryGold : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready to Serve', 
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  _isAvailable ? 'Visible to all customers' : 'Hidden from menu',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isAvailable,
                            onChanged: (value) => setState(() => _isAvailable = value),
                            activeColor: AppTheme.primaryGold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Exclusive Feature Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded, 
                            color: _isPromoted ? AppTheme.primaryGold : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exclusive Deal (Featured)', 
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Show in "Featured Today" on home screen',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isPromoted,
                            onChanged: (value) => setState(() => _isPromoted = value),
                            activeColor: AppTheme.primaryGold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveDish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: AppTheme.warmCharcoal,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryGold.withValues(alpha: 0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.warmCharcoal))
                          : Text('PUBLISH DISH', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 22),
        filled: true,
        fillColor: isDark ? AppTheme.darkCard : Colors.grey[50],
        alignLabelWithHint: true,
        labelStyle: GoogleFonts.outfit(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          color: AppTheme.primaryGold,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
        hintStyle: GoogleFonts.outfit(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
