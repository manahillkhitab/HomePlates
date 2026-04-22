import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/dish_provider.dart';
import '../providers/social_provider.dart';
import '../providers/order_provider.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

import '../widgets/state_wrapper.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/dish_card.dart';
import '../widgets/filter_modal.dart';
import '../widgets/story_circle.dart';

import '../data/local/models/notification_model.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/user_model.dart';
import '../data/local/services/recommendation_service.dart';
import '../data/local/services/sync_service.dart';

import 'role_selection_screen.dart';
import 'browse_dishes_screen.dart';
import 'my_orders_screen.dart';
import 'settings_screen.dart';
import 'notification_history_screen.dart';
import 'cart_screen.dart';
import 'story_viewer_screen.dart';
import 'conversations_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await SyncService().syncAll();
          ref.invalidate(dishProvider);
          ref.invalidate(orderProvider);
          ref.read(socialProvider.notifier).loadPosts(); 
        },
        color: AppTheme.primaryGold,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Modern Sliver App Bar
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
                  'HomePlates',
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
                          tooltip: 'Notifications',
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
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => Navigator.push(context, FadeInRoute(page: const SettingsScreen())),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // 2. Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Customer'}! 👋',
                      style: AppTextStyles.headingSmall(
                        color: isDark ? Colors.white70 : AppTheme.warmCharcoal.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Stories Section
                    _buildStoriesSection(context, ref),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Search Bar
                    _buildSearchBar(context, ref, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildCategoryChip(ref, 'All', isDark),
                          _buildCategoryChip(ref, 'Pakistani', isDark),
                          _buildCategoryChip(ref, 'Fast Food', isDark),
                          _buildCategoryChip(ref, 'Deserts', isDark),
                          _buildCategoryChip(ref, 'Healthy', isDark),
                          _buildCategoryChip(ref, 'Drinks', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text('Quick Actions', style: AppTextStyles.headingLarge(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildQuickAction(context, Icons.restaurant_menu_rounded, 'Browse', () {
                           Navigator.push(context, FadeInRoute(page: const BrowseDishesScreen()));
                        }),
                        const SizedBox(width: AppSpacing.md),
                        _buildQuickAction(context, Icons.shopping_bag_rounded, 'Orders', () {
                           Navigator.push(context, FadeInRoute(page: const MyOrdersScreen()));
                        }, badgeCount: ref.watch(orderProvider).value?.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.rejected && o.status != OrderStatus.canceled).length ?? 0),
                        const SizedBox(width: AppSpacing.md),
                        _buildQuickAction(context, Icons.chat_bubble_rounded, 'Messages', () {
                             Navigator.push(context, FadeInRoute(page: const ConversationsScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    if (user != null && user.orderedCategories.isNotEmpty) ...[
                      Text('Recommended for You 🎯', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                      const SizedBox(height: AppSpacing.md),
                      _buildRecommendedDishes(ref, user),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    
                    Text('Featured Today ✨', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                    const SizedBox(height: AppSpacing.md),
                    _buildPromotedDishes(ref),
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text('Available Today', style: AppTextStyles.headingMedium(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            
            // 3. Dish List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: _buildDishGrid(ref),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: ref.watch(cartProvider).items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, FadeInRoute(page: const CartScreen())),
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.warmCharcoal,
              icon: const Icon(Icons.shopping_basket_rounded),
              label: Text(
                'View Cart (${ref.watch(cartProvider).itemCount})',
                style: AppTextStyles.labelLarge(color: AppTheme.warmCharcoal),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: AppTheme.shadowSm(isDark),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        style: AppTextStyles.bodyLarge(color: isDark ? Colors.white : AppTheme.warmCharcoal),
        textAlignVertical: TextAlignVertical.center,
        onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
        decoration: InputDecoration(
          hintText: 'Search for homemade dishes...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: ref.watch(filterProvider).sortBy != 'Newest' || ref.watch(filterProvider).minRating != 0.0 
                ? AppTheme.primaryGold 
                : (isDark ? Colors.white24 : Colors.black26),
            ),
            onPressed: () async {
              final currentFilters = ref.read(filterProvider);
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterModal(
                  currentPriceRange: currentFilters.priceRange,
                  currentMinRating: currentFilters.minRating,
                  currentSortBy: currentFilters.sortBy,
                ),
              );

              if (result != null) {
                ref.read(filterProvider.notifier).updateFilters(
                  priceRange: result['priceRange'],
                  minRating: result['minRating'],
                  sortBy: result['sortBy'],
                );
              }
            },
          ),
          hintStyle: AppTextStyles.bodyMedium(color: isDark ? Colors.white38 : Colors.black38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStoriesSection(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(socialProvider);

    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kitchen Stories 📸', style: AppTextStyles.headingSmall()),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCircle(
                post: story,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoryViewerScreen(post: story)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {int badgeCount = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            ),
            boxShadow: AppTheme.shadowSm(isDark),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.primaryGold, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(label, style: AppTextStyles.labelLarge(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotedDishes(WidgetRef ref) {
    final allDishes = ref.watch(dishProvider);
    final promotedDishes = allDishes.value?.where((d) => d.isPromoted).toList() ?? [];

    if (promotedDishes.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.primaryGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Check back later for exclusive deals!',
            style: AppTextStyles.bodyMedium(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: promotedDishes.length,
        itemBuilder: (context, index) {
          final dish = promotedDishes[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: DishCard(dish: dish),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedDishes(WidgetRef ref, user) {
    final allDishes = ref.watch(dishProvider);
    final recommended = RecommendationService.getRecommendedDishes(user, allDishes.value ?? []);

    if (recommended.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recommended.length,
        itemBuilder: (context, index) {
          final dish = recommended[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: DishCard(dish: dish),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(WidgetRef ref, String label, bool isDark) {
    final selectedCat = ref.watch(categoryProvider);
    final isSelected = selectedCat == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => ref.read(categoryProvider.notifier).update(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold : (isDark ? AppTheme.darkCard : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGold : (isDark ? Colors.white24 : AppTheme.warmCharcoal.withValues(alpha: 0.2)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium(
              color: isSelected ? AppTheme.warmCharcoal : (isDark ? Colors.white : AppTheme.warmCharcoal),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDishGrid(WidgetRef ref) {
    final dishesAsync = ref.watch(dishProvider);
    final category = ref.watch(categoryProvider);

    return SliverToBoxAdapter(
      child: StateWrapper(
        state: dishesAsync,
        loading: () => const SkeletonLoader.card(count: 4),
        empty: () => EmptyState(
          icon: Icons.restaurant_menu,
          message: 'No dishes available at the moment',
          actionLabel: 'Refresh',
          onAction: () => ref.invalidate(dishProvider),
        ),
        isEmpty: (dishes) {
          final filtered = category == 'All' 
              ? dishes 
              : dishes.where((d) => d.category == category).toList();
          return filtered.isEmpty;
        },
        data: (dishes) {
          final filtered = category == 'All' 
              ? dishes.where((d) => d.isAvailable).toList()
              : dishes.where((d) => d.category == category && d.isAvailable).toList();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.72,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => DishCard(dish: filtered[index]),
          );
        },
      ),
    );
  }
}


