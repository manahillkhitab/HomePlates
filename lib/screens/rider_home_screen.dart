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
import '../data/local/models/order_model.dart';

import 'rider_available_orders_screen.dart';
import 'rider_active_delivery_screen.dart';
import 'rider_delivery_history_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';
import 'role_selection_screen.dart';
import 'status_message_screen.dart';
import 'notification_history_screen.dart';

class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;
    
    // Status Guard
    if (user != null && user.status != UserStatus.approved) {
      return StatusMessageScreen(status: user.status);
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
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Rider Console',
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
                          top: 10,
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
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 26),
                onPressed: () => Navigator.push(context, FadeInRoute(page: const SettingsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 26),
                onPressed: () => _handleLogout(context, ref),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay safe on the road, ${user?.name ?? 'Rider'}! 🛵',
                    style: AppTextStyles.headingSmall(
                      color: isDark ? Colors.white70 : AppTheme.warmCharcoal.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Stats Summary Card
                  Consumer(
                    builder: (context, ref, _) {
                      final wallet = ref.watch(walletProvider(user?.id ?? ''));
                      final historyOrders = ref.watch(riderEarningsProvider(user?.id ?? '')).length;
                      
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.warmCharcoal, Colors.black],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
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
                                  style: AppTextStyles.labelMedium(color: Colors.white54).copyWith(letterSpacing: 2),
                                ),
                                const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryGold, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Rs. ${wallet.balance.toStringAsFixed(0)}',
                              style: AppTextStyles.displayLarge(color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _buildMiniStat(Icons.moped_rounded, '$historyOrders Trips'),
                                const SizedBox(width: 24),
                                _buildMiniStat(Icons.star_rounded, '4.9 Rating'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: AppTheme.primaryGold, size: 20),
                      const SizedBox(width: 12),
                      Text('Weekly Fleet Performance', style: AppTextStyles.headingMedium()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Consumer(
                    builder: (context, ref, _) {
                      final wallet = ref.watch(walletProvider(user?.id ?? ''));
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          boxShadow: AppTheme.shadowSm(isDark),
                        ),
                        child: SimpleBarChart(
                          data: wallet.getWeeklyEarnings(),
                          barColor: Colors.cyanAccent,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  Text('Logistic Operations', style: AppTextStyles.headingMedium()),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Quick Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                    children: [
                      _buildActionCard(
                        context, 
                        Icons.explore_rounded, 
                        'Available', 
                        'High demand zones', 
                        () => Navigator.push(context, FadeInRoute(page: const RiderAvailableOrdersScreen())), 
                        color: AppTheme.primaryGold
                      ),
                      _buildActionCard(
                        context, 
                        Icons.electric_moped_rounded, 
                        'Active', 
                        'Current delivery', 
                        () => Navigator.push(context, FadeInRoute(page: const RiderActiveDeliveryScreen())), 
                        color: Colors.cyanAccent
                      ),
                      _buildActionCard(
                        context, 
                        Icons.history_rounded, 
                        'History', 
                        'Past milestones', 
                        () => Navigator.push(context, FadeInRoute(page: const RiderDeliveryHistoryScreen())), 
                        color: isDark ? Colors.white54 : Colors.grey
                      ),
                       _buildActionCard(
                        context, 
                        Icons.account_balance_wallet_rounded, 
                        'Wallet', 
                        'Payout history', 
                        () => Navigator.push(context, FadeInRoute(page: const WalletScreen())), 
                        color: Colors.orangeAccent
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryGold),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelMedium(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {required Color color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          boxShadow: AppTheme.shadowSm(isDark),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headingSmall(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: AppTextStyles.caption(color: isDark ? Colors.white38 : AppTheme.warmCharcoal.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
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
}


