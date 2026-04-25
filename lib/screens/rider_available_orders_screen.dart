import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';

import '../widgets/app_button.dart';
import '../widgets/state_wrapper.dart';

class RiderAvailableOrdersScreen extends ConsumerStatefulWidget {
  const RiderAvailableOrdersScreen({super.key});

  @override
  ConsumerState<RiderAvailableOrdersScreen> createState() =>
      _RiderAvailableOrdersScreenState();
}

class _RiderAvailableOrdersScreenState
    extends ConsumerState<RiderAvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadAvailableOrders();
    });
  }

  Future<void> _pickUpOrder(OrderModel order) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final error = await ref
        .read(orderProvider.notifier)
        .claimOrder(order, user.id);

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery mission accepted!',
            style: AppTextStyles.bodyMedium(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: AppTextStyles.bodyMedium(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncOrders = ref.watch(orderProvider);

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
              'Available Missions',
              style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
            ),
            centerTitle: true,
            pinned: true,
          ),
          asyncOrders.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to sync orders',
                      style: AppTextStyles.headingMedium(),
                    ),
                  ],
                ),
              ),
            ),
            data: (ordersList) {
              if (ordersList.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.moped_rounded,
                    message: 'The road is quiet',
                    actionLabel: '',
                    onAction: () {},
                    subtitle:
                        'New orders will appear here when ready for pickup. Keep your app open!',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final order = ordersList[index];
                    return _buildOrderCard(order, isDark, theme);
                  }, childCount: ordersList.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: AppTheme.primaryGold),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: AppTheme.primaryGold),
        );
      }
      return const Icon(Icons.restaurant, color: AppTheme.primaryGold);
    }
  }

  Widget _buildOrderCard(OrderModel order, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm(isDark),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Dish Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: order.dishImagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          child: _buildImage(order.dishImagePath),
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: AppTheme.primaryGold,
                          size: 32,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.dishName,
                        style: AppTextStyles.headingSmall(
                          color: isDark ? Colors.white : AppTheme.warmCharcoal,
                        ).copyWith(letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Text(
                              '${order.quantity} ITEMS',
                              style: AppTextStyles.labelSmall(
                                color: AppTheme.primaryGold,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rs. ${order.totalPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.headingMedium(
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (order.deliveryAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To: Customer (Address Hidden)',
                      style: AppTextStyles.bodyMedium(
                        color: Colors.grey,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

          // Pickup Details & Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50],
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PICKUP: ${order.chefName}',
                          style:
                              AppTextStyles.labelMedium(
                                color: Colors.greenAccent,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AppButton.primary(
                    text: 'ACCEPT',
                    onPressed: () => _pickUpOrder(order),
                    backgroundColor: Colors.greenAccent,
                    height: 44,
                    isExpanded: false,
                    textStyle: AppTextStyles.labelLarge(
                      color: AppTheme.warmCharcoal,
                    ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
