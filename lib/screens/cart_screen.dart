import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/eta_service.dart';

import '../widgets/app_button.dart';
import '../widgets/state_wrapper.dart';
import '../data/local/models/cart_summary.dart';
import 'checkout_review_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.warmCharcoal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Basket',
          style: AppTextStyles.headingLarge(color: AppTheme.primaryGold),
        ),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(context, ref, item, isDark);
                    },
                  ),
                ),

                _buildScheduleSection(context, ref, cart, isDark),
                _buildCheckoutSummary(context, ref, cart, user, isDark),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_basket_rounded,
      message: 'Your basket is empty',
      actionLabel: 'Browse Dishes',
      onAction: () => Navigator.pop(context),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.shadowSm(isDark),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? (item.imagePath!.startsWith('http')
                      ? Image.network(
                          item.imagePath!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildItemImageFallback(item.name),
                        )
                      : Image.file(
                          File(item.imagePath!),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildItemImageFallback(item.name),
                        ))
                : _buildItemImageFallback(item.name),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.headingSmall(
                    color: isDark ? Colors.white : AppTheme.warmCharcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.labelLarge(color: AppTheme.primaryGold),
                ),
                if (item.selectedOptions != null &&
                    item.selectedOptions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '+ ${item.selectedOptions!.length} extras',
                      style: AppTextStyles.caption(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkAccent : AppTheme.offWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _buildIconButton(
                  Icons.remove,
                  () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.dishId, item.quantity - 1),
                  isDark,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.bodyLarge(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildIconButton(
                  Icons.add,
                  () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.dishId, item.quantity + 1),
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : AppTheme.warmCharcoal,
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary(
    BuildContext context,
    WidgetRef ref,
    CartSummary cart,
    dynamic user,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyles.bodyMedium(color: Colors.grey),
              ),
              Text(
                'Rs. ${cart.total.toStringAsFixed(0)}',
                style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            text: 'CHECKOUT NOW',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutReviewScreen(cart: cart),
                ),
              );
            },
            isExpanded: true,
            height: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    WidgetRef ref,
    CartSummary cart,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppTheme.primaryGold),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Time',
                  style: AppTextStyles.labelMedium(color: Colors.grey),
                ),
                Text(
                  cart.scheduledTime == null
                      ? 'ASAP (~${ETAService.calculateCartETA(cart)})'
                      : DateFormat('MMM d, h:mm a').format(cart.scheduledTime!),
                  style: AppTextStyles.headingSmall(
                    color: isDark ? Colors.white : AppTheme.warmCharcoal,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pickDateTime(context, ref, cart),
            child: Text(
              'CHANGE',
              style: AppTextStyles.labelLarge(color: AppTheme.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(
    BuildContext context,
    WidgetRef ref,
    CartSummary cart,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          now.add(const Duration(minutes: 45)),
        ),
      );

      if (time != null) {
        final scheduled = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (scheduled.isBefore(now.add(const Duration(minutes: 30)))) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please schedule at least 30 mins in advance'),
              ),
            );
          }
          return;
        }
        ref.read(cartProvider.notifier).updateScheduledTime(scheduled);
      }
    }
  }

  Widget _buildItemImageFallback(String itemName) {
    String name = itemName.toLowerCase();
    String url =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=200&q=80';

    if (name.contains('donuts')) {
      url =
          'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=200&q=80';
    } else if (name.contains('pulao') || name.contains('rice')) {
      url =
          'https://images.unsplash.com/photo-1512058560566-d8b437bfb1d8?auto=format&fit=crop&w=200&q=80';
    }

    return Image.network(
      url,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 70,
        height: 70,
        color: AppTheme.primaryGold.withValues(alpha: 0.1),
        child: const Icon(Icons.restaurant, color: AppTheme.primaryGold),
      ),
    );
  }
}
