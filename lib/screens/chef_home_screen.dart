import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/earnings_provider.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';

import '../widgets/simple_bar_chart.dart';
import '../widgets/app_button.dart';

import '../data/local/models/user_model.dart';
import '../data/local/models/notification_model.dart';

import 'role_selection_screen.dart';
import 'my_dishes_screen.dart';
import 'chef_orders_screen.dart';
import 'wallet_screen.dart';
import 'chef_subscription_screen.dart';
import 'status_message_screen.dart';
import 'settings_screen.dart';
import 'earnings_screen.dart';
import 'notification_history_screen.dart';
import 'chef_create_story_screen.dart';
import 'reviews_screen.dart';
import 'chef_profile_screen.dart';

class ChefHomeScreen extends ConsumerWidget {
  const ChefHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chef = ref.watch(authProvider).value;
    
    // Status Guard
    if (chef != null && chef.status != UserStatus.approved) {
      return StatusMessageScreen(status: chef.status);
    }
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
              expandedTitleScale: 1.1,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Chef Console',
                style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
              ),
              centerTitle: false,
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: Hive.box<NotificationModel>(AppConstants.notificationBox).listenable(),
                builder: (context, Box<NotificationModel> box, _) {
                  final unread = box.values.where((n) => !n.isRead).length;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 26),
                        onPressed: () => Navigator.push(context, FadeInRoute(page: const NotificationHistoryScreen())),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: AppTextStyles.caption(color: Colors.white).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context, FadeInRoute(page: const SettingsScreen())),
              ),
              const SizedBox(width: 4),
              Switch(
                value: !(chef?.isKitchenClosed ?? false),
                onChanged: (_) => ref.read(authProvider.notifier).toggleKitchenStatus(),
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _handleLogout(context, ref),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (chef?.isKitchenClosed ?? false)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.redAccent.withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    'KITCHEN IS CURRENTLY OFFLINE 😴',
                    style: AppTextStyles.labelSmall(
                      color: Colors.redAccent,
                    ).copyWith(letterSpacing: 1),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Chef ${chef?.name ?? ''}! 👨‍🍳',
                    style: AppTextStyles.headingSmall(color: isDark ? Colors.white70 : AppTheme.warmCharcoal.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  Consumer(
                    builder: (context, ref, _) {
                      final wallet = ref.watch(walletProvider(chef?.id ?? ''));
                      final earnings = ref.watch(earningsStatsProvider(chef?.id ?? ''));
                      final orders = earnings.totalOrders;
                      
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGold, const Color(0xFFFF8F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'WALLET BALANCE',
                                  style: AppTextStyles.labelMedium(color: AppTheme.warmCharcoal.withValues(alpha: 0.6)).copyWith(letterSpacing: 2),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warmCharcoal.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.warmCharcoal, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Rs. ${wallet.balance.toStringAsFixed(0)}',
                              style: AppTextStyles.displayLarge(color: AppTheme.warmCharcoal),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _buildMiniStat(Icons.shopping_bag_rounded, '$orders Orders'),
                                const SizedBox(width: 20),
                                _buildStatLink(context, 'Withdrawal', () => Navigator.push(context, FadeInRoute(page: const WalletScreen()))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Weekly Performance', Icons.insights_rounded),
                  const SizedBox(height: AppSpacing.md),
                  Consumer(
                    builder: (context, ref, child) {
                      final wallet = ref.watch(walletProvider(chef?.id ?? ''));
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          boxShadow: AppTheme.shadowSm(isDark),
                        ),
                        child: SimpleBarChart(data: wallet.getWeeklyEarnings()),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Text('Kitchen Management', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Quick Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.9,
                    children: [
                      _buildActionCard(context, Icons.restaurant_menu_rounded, 'My Dishes', 'Manage your menu', () {
                         Navigator.push(context, FadeInRoute(page: const MyDishesScreen()));
                      }),
                      _buildActionCard(context, Icons.receipt_long_rounded, 'Orders', 'View incoming requests', () {
                         Navigator.push(context, FadeInRoute(page: const ChefOrdersScreen()));
                      }),
                      _buildActionCard(context, Icons.account_balance_wallet_rounded, 'Wallet', 'Payout & history', () {
                         Navigator.push(context, FadeInRoute(page: const WalletScreen()));
                      }),
                      _buildActionCard(context, Icons.insights_rounded, 'Insights', 'Business growth', () {
                         Navigator.push(context, FadeInRoute(page: const EarningsScreen()));
                      }),
                      _buildActionCard(context, Icons.star_border_purple500_rounded, 'Premium', 'Lower your fees', () {
                         Navigator.push(context, FadeInRoute(page: const ChefSubscriptionScreen()));
                      }),
                      _buildActionCard(context, Icons.camera_alt_rounded, 'Stories', 'Share updates', () {
                         Navigator.push(context, FadeInRoute(page: const ChefCreateStoryScreen()));
                      }),
                      _buildActionCard(context, Icons.reviews_rounded, 'Reviews', 'Customer feedback', () {
                         final chef = ref.read(authProvider).value;
                         if (chef != null) {
                           Navigator.push(context, FadeInRoute(page: ReviewsScreen(chefId: chef.id)));
                         }
                      }),
                      _buildActionCard(context, Icons.storefront_rounded, 'My Profile', 'View as customer', () {
                         final chef = ref.read(authProvider).value;
                         if (chef != null) {
                           Navigator.push(context, FadeInRoute(page: ChefProfileScreen(chefId: chef.id)));
                         }
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warmCharcoal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.warmCharcoal.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium(color: AppTheme.warmCharcoal),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.warmCharcoal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.warmCharcoal),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelSmall(color: AppTheme.warmCharcoal)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            width: 1.5,
          ),
          boxShadow: AppTheme.shadowSm(isDark),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryGold, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headingSmall(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: AppTextStyles.caption(color: isDark ? Colors.white38 : AppTheme.warmCharcoal.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        FadeInRoute(page: const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.headingMedium()),
      ],
    );
  }
}
