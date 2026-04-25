import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../data/local/models/order_model.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';

import '../widgets/app_button.dart';
import '../widgets/state_wrapper.dart';

class ChefOrdersScreen extends ConsumerStatefulWidget {
  const ChefOrdersScreen({super.key});
  // ... (imports are top level, but replace tool needs context. I will do 2 chunks)
  // Chunk 1: Imports

  @override
  ConsumerState<ChefOrdersScreen> createState() => _ChefOrdersScreenState();
}

class _ChefOrdersScreenState extends ConsumerState<ChefOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        ref.read(orderProvider.notifier).loadOrdersForChef(user.id);
      }
    });
  }

  Future<void> _updateStatus(
    OrderModel order,
    OrderStatus newStatus, {
    String? reason,
  }) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final success = await ref
        .read(orderProvider.notifier)
        .updateOrderStatus(
          order: order,
          newStatus: newStatus,
          currentUser: user,
          cancelReason: reason,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as ${newStatus.name}')),
      );
    }
  }

  Future<void> _handleReject(OrderModel order) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Order?', style: AppTextStyles.headingMedium()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for the customer:',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g. Out of ingredients',
                hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.primaryGold.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: AppTextStyles.labelLarge(color: Colors.grey),
            ),
          ),
          AppButton.primary(
            text: 'REJECT',
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.redAccent,
            height: 40,
            isExpanded: false,
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = reasonController.text.trim();
      _updateStatus(
        order,
        OrderStatus.rejected,
        reason: reason.isEmpty ? 'Not specified by chef' : reason,
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
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                'Kitchen Queue',
                style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
              ),
              centerTitle: false,
            ),
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
                      'Oops! Something went wrong',
                      style: AppTextStyles.headingMedium(),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (ordersList) {
              final sortedOrders = ordersList.toList()
                ..sort((a, b) {
                  if (a.status == OrderStatus.pending &&
                      b.status != OrderStatus.pending) {
                    return -1;
                  }
                  if (a.status != OrderStatus.pending &&
                      b.status == OrderStatus.pending) {
                    return 1;
                  }
                  return b.createdAt.compareTo(a.createdAt);
                });

              if (sortedOrders.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.restaurant_rounded,
                    message: 'No active orders',
                    actionLabel: 'Check Menu',
                    onAction: () => Navigator.pop(context), // Or just no action
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final order = sortedOrders[index];
                    return _buildOrderCard(order, isDark);
                  }, childCount: sortedOrders.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isDark) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: order.status == OrderStatus.pending
              ? AppTheme.primaryGold.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: AppTheme.shadowSm(isDark),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    image: order.dishImagePath.isNotEmpty
                        ? DecorationImage(
                            image:
                                (order.dishImagePath.startsWith('http')
                                        ? CachedNetworkImageProvider(
                                            order.dishImagePath,
                                          )
                                        : FileImage(File(order.dishImagePath)))
                                    as ImageProvider,
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child:
                      order.dishImagePath.isEmpty || order.dishImagePath == ''
                      ? Center(
                          child: Text(
                            '${order.quantity}x',
                            style: AppTextStyles.headingMedium(
                              color: statusColor,
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Text(
                              '${order.quantity}x',
                              style: AppTextStyles.labelSmall(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
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
                       if (order.customerName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'For ${order.customerName}',
                          style: AppTextStyles.bodySmall(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status.name.toUpperCase(),
                              style: AppTextStyles.labelSmall(
                                color: statusColor,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              timeago.format(order.createdAt),
                              style: AppTextStyles.caption(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${order.totalPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.headingMedium(
                    color: AppTheme.primaryGold,
                  ),
                ),
              ],
            ),
          ),

          if (order.deliveryAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery to: ${order.deliveryAddress}',
                      style: AppTextStyles.labelMedium(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.cardRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: #${order.id.substring(0, 6)}',
                  style: AppTextStyles.caption(color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildActionButtons(order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.primaryGold;
      case OrderStatus.accepted:
        return Colors.blueAccent;
      case OrderStatus.cooking:
        return Colors.orangeAccent;
      case OrderStatus.ready:
        return Colors.greenAccent;
      case OrderStatus.pickedUp:
        return Colors.purpleAccent;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.redAccent;
      case OrderStatus.canceled:
        return Colors.grey;
      case OrderStatus.completed:
        return Colors.green;
    }
  }

  List<Widget> _buildActionButtons(OrderModel order) {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          TextButton(
            onPressed: () => _handleReject(order),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(
              'Reject',
              style: AppTextStyles.labelLarge(color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            text: 'Accept',
            onPressed: () => _updateStatus(order, OrderStatus.accepted),
            height: 36,
            isExpanded: false,
            textStyle: AppTextStyles.labelLarge(
              color: AppTheme.warmCharcoal,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ];
      case OrderStatus.accepted:
        return [
          AppButton.primary(
            text: 'Start Cooking',
            onPressed: () => _updateStatus(order, OrderStatus.cooking),
            backgroundColor: Colors.blueAccent,
            height: 36,
            isExpanded: false,
            icon: Icons.outdoor_grill_rounded,
            textStyle: AppTextStyles.labelLarge(
              color: Colors.white,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ];
      case OrderStatus.cooking:
        return [
          AppButton.primary(
            text: 'Mark Ready',
            onPressed: () => _updateStatus(order, OrderStatus.ready),
            backgroundColor: Colors.greenAccent,
            textStyle: AppTextStyles.labelLarge(
              color: AppTheme.warmCharcoal,
            ).copyWith(fontWeight: FontWeight.bold),
            height: 36,
            isExpanded: false,
            icon: Icons.check_circle_rounded,
          ),
        ];
      case OrderStatus.ready:
        return [
          Row(
            children: [
              const Icon(Icons.timer_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Waiting for Rider',
                style: AppTextStyles.labelMedium(color: Colors.grey),
              ),
            ],
          ),
        ];
      case OrderStatus.pickedUp:
        return [
          Row(
            children: [
              const Icon(
                Icons.moped_rounded,
                size: 14,
                color: Colors.purpleAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'With Rider',
                style: AppTextStyles.labelMedium(color: Colors.purpleAccent),
              ),
            ],
          ),
        ];
      case OrderStatus.rejected:
      case OrderStatus.canceled:
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return [
          Text(
            'Completed',
            style: AppTextStyles.labelMedium(color: Colors.grey),
          ),
        ];
    }
  }
}
