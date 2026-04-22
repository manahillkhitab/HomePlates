import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/models/dish_model.dart';
import '../data/local/models/dish_option.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';

import '../widgets/app_button.dart';
import 'cart_screen.dart';
import 'chef_profile_screen.dart';
import 'chat_screen.dart';

class DishDetailScreen extends ConsumerStatefulWidget {
  final DishModel dish;

  const DishDetailScreen({super.key, required this.dish});

  @override
  ConsumerState<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends ConsumerState<DishDetailScreen> {
  int _quantity = 1;
  bool _isLoading = false;
  late List<DishOption> _customOptions;

  @override
  void initState() {
    super.initState();
    _customOptions = widget.dish.options.map((o) => o.copyWith(isSelected: false)).toList();
  }

  double get _optionsTotal {
    return _customOptions
        .where((o) => o.isSelected)
        .fold(0, (sum, item) => sum + item.price);
  }

  double get _totalPrice => (widget.dish.price + _optionsTotal) * _quantity;

  void _incrementQuantity() => setState(() => _quantity++);

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _addToCart() async {
    final cart = ref.read(cartProvider);
    
    if (cart.chefId != null && cart.chefId != widget.dish.chefId) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Replace Cart?', style: AppTextStyles.headingMedium()),
          content: Text('Your cart contains items from another kitchen. Would you like to clear it and add this instead?', style: AppTextStyles.bodyMedium()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('NO', style: AppTextStyles.labelLarge(color: Colors.grey)),
            ),
            AppButton.primary(
              text: 'YES, REPLACE',
              onPressed: () => Navigator.pop(context, true),
              height: 40,
              isExpanded: false,
            ),
          ],
        ),
      );

      if (clear == true) {
        await ref.read(cartProvider.notifier).clearCart();
      } else {
        return;
      }
    }

    setState(() => _isLoading = true);
    final selectedOptions = _customOptions.where((o) => o.isSelected).toList();
    await ref.read(cartProvider.notifier).addToCart(widget.dish, _quantity, selectedOptions: selectedOptions);
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.dish.name} added to cart!', style: AppTextStyles.bodyMedium(color: Colors.white)),
          backgroundColor: AppTheme.warmCharcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: AppTheme.primaryGold,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Hero(
                    tag: 'dish_${widget.dish.id}',
                    child: Container(
                      height: 380,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
                        child: widget.dish.imagePath.isNotEmpty
                            ? (widget.dish.imagePath.startsWith('http')
                                ? Image.network(
                                    widget.dish.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                                  )
                                : Image.file(
                                    File(widget.dish.imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                                  ))
                            : _buildImageFallback(size: 80),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.dish.name,
                                  style: AppTextStyles.displayMedium(
                                    color: isDark ? Colors.white : AppTheme.warmCharcoal,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.8 (120+ reviews)',
                                      style: AppTextStyles.labelMedium(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${widget.dish.price.toStringAsFixed(0)}',
                            style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Kitchen & Chat Links
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(chefId: widget.dish.chefId))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 16),
                                  const SizedBox(width: 6),
                                  Text('VISIT KITCHEN', style: AppTextStyles.labelSmall(color: AppTheme.primaryGold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  otherUserId: widget.dish.chefId,
                                  otherUserName: 'Chef',
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text('About Dish', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.dish.description,
                        style: AppTextStyles.bodyLarge(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text('Quantity', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildQuantityButton(Icons.remove_rounded, _decrementQuantity, isDark),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              '$_quantity',
                              style: AppTextStyles.displayMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal),
                            ),
                          ),
                          _buildQuantityButton(Icons.add_rounded, _incrementQuantity, isDark),
                        ],
                      ),
                      
                      if (_customOptions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text('Customize Your Meal', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                        const SizedBox(height: AppSpacing.md),
                        ..._customOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: option.isSelected ? AppTheme.primaryGold : (isDark ? Colors.white10 : Colors.black12),
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: option.isSelected,
                              onChanged: (val) {
                                setState(() {
                                  _customOptions[index] = option.copyWith(isSelected: val ?? false);
                                });
                              },
                              title: Text(
                                option.name,
                                style: AppTextStyles.headingSmall(color: isDark ? Colors.white : AppTheme.warmCharcoal),
                              ),
                              subtitle: Text(
                                '+ Rs. ${option.price.toStringAsFixed(0)}',
                                style: AppTextStyles.labelMedium(color: AppTheme.primaryGold),
                              ),
                              activeColor: AppTheme.primaryGold,
                              checkColor: AppTheme.warmCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          );
                        }).toList(),
                      ],
                      const SizedBox(height: 100), // Bottom padding for sticky bar
                    ]),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: AppTextStyles.caption(color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        'Rs. ${_totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.headingLarge(color: AppTheme.primaryGold),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton.primary(
                    text: 'Add to Cart',
                    onPressed: _isLoading ? null : _addToCart,
                    isLoading: _isLoading,
                    height: 56,
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkAccent : AppTheme.offWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : AppTheme.warmCharcoal, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImageFallback({double size = 50}) {
    String name = widget.dish.name.toLowerCase();
    String url = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80'; 
    
    if (name.contains('donuts')) url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=800&q=80';
    else if (name.contains('pulao') || name.contains('rice')) url = 'https://images.unsplash.com/photo-1512058560566-d8b437bfb1d8?auto=format&fit=crop&w=800&q=80';
    else if (name.contains('burger')) url = 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80';
    else if (name.contains('pizza')) url = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80';

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.restaurant, size: size, color: Colors.grey[600]),
      ),
    );
  }
}
