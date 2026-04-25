import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/constants.dart';

import '../data/local/services/sync_service.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/user_model.dart';
import '../providers/config_provider.dart';

import 'admin_user_list_screen.dart';
import 'admin_order_list_screen.dart';
import 'admin_payouts_screen.dart';
import 'admin_settings_screen.dart';
import 'role_selection_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SyncService _syncService = SyncService();
  bool _isLoading = true;
  bool _isSyncing = false;

  // Stats
  int _totalUsers = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  int _pendingApprovals = 0;
  int _activeRiders = 0;

  // Data for Charts & Lists
  List<dynamic> _recentActivity = []; // Combined feed of orders and signups

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool isOnline = true;
    try {
      final dynamic connectivityResult = await Connectivity()
          .checkConnectivity();
      if (connectivityResult is List) {
        isOnline = !connectivityResult.contains(ConnectivityResult.none);
      } else {
        isOnline = connectivityResult != ConnectivityResult.none;
      }
    } catch (_) {
      isOnline = false;
    }

    try {
      List<dynamic> users = [];
      List<dynamic> orders = [];

      if (isOnline) {
        // 1. Fetch Users from Cloud
        final usersRes = await _supabase
            .from('users')
            .select('id, role, status, name, created_at, kitchen_name')
            .order('created_at', ascending: false);
        users = usersRes as List<dynamic>;

        // 2. Fetch Orders from Cloud
        final ordersRes = await _supabase
            .from('orders')
            .select(
              'id, total_price, created_at, status, dish_name, customer_id',
            )
            .order('created_at', ascending: false);
        orders = ordersRes as List<dynamic>;
      } else {
        // Fallback to Hive
        final userBox = Hive.box<UserModel>(AppConstants.userBox);
        final orderBox = Hive.box<OrderModel>(AppConstants.orderBox);

        users = userBox.values
            .map(
              (u) => <String, dynamic>{
                'id': u.id,
                'role': u.role.name,
                'status': u.status.name,
                'name': u.name,
                'created_at': u.createdAt.toIso8601String(),
                'kitchen_name': u.kitchenName,
              },
            )
            .toList();

        orders = orderBox.values
            .map(
              (o) => <String, dynamic>{
                'id': o.id,
                'total_price': o.totalPrice,
                'created_at': o.createdAt.toIso8601String(),
                'status': o.status.name,
                'dish_name': o.dishName,
                'customer_id': o.customerId,
              },
            )
            .toList();

        debugPrint(
          'Offline: Loaded ${users.length} users and ${orders.length} orders from Hive',
        );
      }

      int pending = 0;
      int riders = 0;
      for (var u in users) {
        if (u['status']?.toString().toLowerCase() == 'pending') pending++;
        if (u['role']?.toString().toLowerCase() == 'rider' &&
            u['status']?.toString().toLowerCase() == 'approved')
          riders++;
      }

      double totalRev = 0;
      for (var o in orders) {
        final status = o['status']?.toString().toLowerCase() ?? 'pending';
        final price =
            double.tryParse(o['total_price']?.toString() ?? '0') ?? 0.0;
        if (status != 'rejected' && status != 'canceled') {
          totalRev += price;
        }
      }

      // 3. Build Recent Activity Feed
      final List<dynamic> feed = [];

      // Add recent orders
      int ordersAdded = 0;
      for (var o in orders) {
        if (ordersAdded >= 5) break;
        final parsedTime = DateTime.tryParse(o['created_at']?.toString() ?? '');
        if (parsedTime == null) continue;
        feed.add(<String, dynamic>{
          'type': 'order',
          'title': 'New Order: ${o['dish_name']}',
          'subtitle': 'Rs. ${o['total_price'] ?? 0}',
          'time': parsedTime,
          'status': o['status']?.toString() ?? 'pending',
          'icon': Icons.shopping_bag_rounded,
          'color': Colors.orangeAccent,
        });
        ordersAdded++;
      }

      // Add recent signups
      int usersAdded = 0;
      for (var u in users) {
        if (usersAdded >= 3) break;
        final parsedTime = DateTime.tryParse(u['created_at']?.toString() ?? '');
        if (parsedTime == null) continue;
        feed.add(<String, dynamic>{
          'type': 'user',
          'title': 'New User: ${u['name']}',
          'subtitle':
              '${u['role']?.toString().toUpperCase() ?? ''} • ${u['status']?.toString() ?? 'pending'}',
          'time': parsedTime,
          'status': u['status']?.toString() ?? 'pending',
          'icon': Icons.person_add_rounded,
          'color': Colors.blueAccent,
        });
        usersAdded++;
      }

      // Sort feed by time
      feed.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
      );

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _pendingApprovals = pending;
          _activeRiders = riders;
          _totalOrders = orders.length;
          _totalRevenue = totalRev;
          _recentActivity = feed.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runSync() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    await _syncService.syncAll();
    await _fetchDashboardData();
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = ref.watch(configProvider).value;
    final platformCommission =
        (1.0 -
                (config?.chefCommission ?? 0.8) -
                (config?.riderCommission ?? 0.1))
            .clamp(0.0, 1.0);
    final totalPlatformRevenue = _totalRevenue * platformCommission;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      body: CustomScrollView(
        slivers: [
          // 1. Premium App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.primaryGold,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Admin Command Center',
                style: AppTextStyles.headingMedium(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppTheme.warmCharcoal, Colors.black]
                        : [AppTheme.primaryGold, Colors.amber.shade200],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, color: Colors.white),
                onPressed: _isSyncing ? null : _runSync,
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSettingsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 4,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SYSTEM OPERATIONAL',
                                style:
                                    AppTextStyles.labelSmall(
                                      color: Colors.green,
                                    ).copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Main Stats Grid
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          shrinkWrap: true,
                          childAspectRatio: 1.3,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildPremiumStatCard(
                              'Total Revenue',
                              'Rs. ${_totalRevenue.toStringAsFixed(0)}',
                              Icons.attach_money_rounded,
                              [Colors.green.shade700, Colors.green.shade400],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminOrderListScreen(),
                                ),
                              ),
                            ),
                            _buildPremiumStatCard(
                              'Total Orders',
                              _totalOrders.toString(),
                              Icons.shopping_bag_outlined,
                              [Colors.orange.shade700, Colors.orange.shade400],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminOrderListScreen(),
                                ),
                              ),
                            ),
                            _buildPremiumStatCard(
                              'Active Users',
                              _totalUsers.toString(),
                              Icons.people_outline,
                              [Colors.blue.shade700, Colors.blue.shade400],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminUserListScreen(
                                        initialFilter: 'all',
                                      ),
                                ),
                              ),
                            ),
                            _buildPremiumStatCard(
                              'Pending Approvals',
                              _pendingApprovals.toString(),
                              Icons.verified_user_outlined,
                              _pendingApprovals > 0
                                  ? [Colors.red.shade700, Colors.red.shade400]
                                  : [
                                      Colors.grey.shade700,
                                      Colors.grey.shade500,
                                    ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminUserListScreen(
                                        initialFilter: 'pending_status',
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Secondary Stats Row
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildMiniStatCard(
                                'Platform Revenue',
                                'Rs. ${totalPlatformRevenue.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                Colors.purple,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _buildMiniStatCard(
                                'Active Riders',
                                '$_activeRiders',
                                Icons.delivery_dining,
                                Colors.teal,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _buildMiniStatCard(
                                'Payouts',
                                'View',
                                Icons.receipt_long,
                                Colors.deepOrange,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminPayoutsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Recent Activity',
                          style: AppTextStyles.headingMedium(),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Recent Activity Feed
                        _recentActivity.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_rounded,
                                        size: 48,
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No recent activity',
                                        style: AppTextStyles.bodyMedium(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentActivity.length,
                                itemBuilder: (context, index) {
                                  final item = _recentActivity[index];
                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.darkCard
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd,
                                      ),
                                      boxShadow: AppTheme.shadowSm(isDark),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (item['color'] as Color)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item['icon'],
                                          color: item['color'],
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        item['title'],
                                        style: AppTextStyles.labelLarge(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.warmCharcoal,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        item['subtitle'],
                                        style: AppTextStyles.bodySmall(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: Text(
                                        _formatTime(item['time']),
                                        style: AppTextStyles.caption(
                                          color: Colors.grey,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                },
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildPremiumStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.headingLarge(
                      color: Colors.white,
                    ).copyWith(fontSize: 22),
                  ),
                  Text(
                    title,
                    style: AppTextStyles.caption(
                      color: Colors.white.withValues(alpha: 0.8),
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: AppTextStyles.labelLarge(
                    color: isDark ? Colors.white : AppTheme.warmCharcoal,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: AppTextStyles.caption(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
