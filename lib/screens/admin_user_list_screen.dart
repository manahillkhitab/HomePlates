import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/constants.dart';

import '../data/local/models/user_model.dart';

import '../widgets/state_wrapper.dart';
import '../widgets/app_button.dart';

class AdminUserListScreen extends StatefulWidget {
  final String? initialFilter;
  const AdminUserListScreen({super.key, this.initialFilter});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late String _selectedRole;
  String _searchQuery = '';
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialFilter ?? 'all';
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    // First, load from Hive (local storage)
    try {
      final userBox = Hive.box<UserModel>(AppConstants.userBox);
      final localUsers = userBox.values
          .map(
            (user) => {
              'id': user.id,
              'name': user.name,
              'email': user.email,
              'phone': user.phone,
              'role': user.role.name,
              'status': user.status.name,
              'address': user.address,
              'kitchenName': user.kitchenName,
            },
          )
          .toList();

      if (mounted && localUsers.isNotEmpty) {
        setState(() {
          _users = localUsers;
        });
      }
    } catch (e) {
      debugPrint('Error loading local users: $e');
    }

    // Then fetch from Supabase
    try {
      final res = await _supabase
          .from('users')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _users = res as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users from Supabase: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    return _users.where((user) {
      bool matchesRole = true;
      if (_selectedRole == 'pending_status') {
        matchesRole =
            (user['status'] as String? ?? 'approved').toLowerCase() ==
            'pending';
      } else if (_selectedRole != 'all') {
        matchesRole =
            (user['role'] as String).toLowerCase() ==
            _selectedRole.toLowerCase();
      }

      final matchesSearch =
          user['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['email'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesRole && matchesSearch;
    }).toList();
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      await _supabase
          .from('users')
          .update({'status': newStatus})
          .eq('id', userId);

      // Update local state
      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index] = {..._users[index], 'status': newStatus};
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to ${newStatus.toUpperCase()}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating user status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'System Users',
          style: AppTextStyles.headingMedium(
            color: isDark ? Colors.white : AppTheme.warmCharcoal,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.warmCharcoal,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyles.bodyMedium(),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Pending', 'pending_status'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Customers', 'customer'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Chefs', 'chef'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Riders', 'rider'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGold,
                    ),
                  )
                : _filteredUsers.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.people_outline,
                      message: 'No users found',
                      actionLabel: '',
                      onAction: () {},
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final role = user['role'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          boxShadow: AppTheme.shadowSm(isDark),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.md),
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(
                              role,
                            ).withValues(alpha: 0.1),
                            child: Icon(
                              _getRoleIcon(role),
                              color: _getRoleColor(role),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'Unknown',
                            style: AppTextStyles.headingSmall(
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.warmCharcoal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'] ?? '',
                                style: AppTextStyles.bodySmall(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(
                                        role,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: AppTextStyles.labelSmall(
                                        color: _getRoleColor(role),
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(
                                    user['status'] ?? 'approved',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          onTap: () => _showUserDetail(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedRole = value);
      },
      selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkCard
          : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
      labelStyle: AppTextStyles.labelMedium(
        color: isSelected ? AppTheme.primaryGold : Colors.grey,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'chef':
        return Icons.restaurant;
      case 'rider':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'chef':
        return Colors.orange;
      case 'rider':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _showUserDetail(dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('User Details', style: AppTextStyles.headingLarge()),
              const SizedBox(height: AppSpacing.lg),
              _detailItem('Name', user['name']),
              _detailItem('Email', user['email']),
              _detailItem('Phone', user['phone'] ?? 'Not provided'),
              _detailItem('Address', user['address'] ?? 'Not provided'),
              _detailItem('Role', (user['role'] as String).toUpperCase()),
              _detailItem(
                'Current Status',
                (user['status'] as String? ?? 'approved').toUpperCase(),
              ),
              if (user['kitchen_name'] != null &&
                  user['kitchen_name'].toString().isNotEmpty)
                _detailItem('Kitchen Name', user['kitchen_name']),
              if (user['vehicle_number'] != null &&
                  user['vehicle_number'].toString().isNotEmpty)
                _detailItem(
                  'Vehicle',
                  '${user['vehicle_type'] ?? ''} - ${user['vehicle_number']}',
                ),
              const SizedBox(height: AppSpacing.xl),

              if ((user['status'] as String? ?? 'approved') == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        text: 'APPROVE',
                        onPressed: () {
                          _updateUserStatus(user['id'], 'approved');
                          Navigator.pop(context);
                        },
                        height: 48,
                        backgroundColor: Colors.green,
                        isExpanded: false,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.destructive(
                        text: 'REJECT',
                        onPressed: () {
                          _updateUserStatus(user['id'], 'rejected');
                          Navigator.pop(context);
                        },
                        height: 48,
                        isExpanded: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ] else if ((user['status'] as String? ?? 'approved') ==
                  'approved') ...[
                AppButton.secondary(
                  text: 'BLOCK USER',
                  onPressed: () {
                    _updateUserStatus(user['id'], 'blocked');
                    Navigator.pop(context);
                  },
                  height: 48,
                  borderColor: Colors.red,
                  textStyle: AppTextStyles.labelLarge(
                    color: Colors.red,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else if ((user['status'] as String? ?? 'approved') ==
                  'blocked') ...[
                AppButton.primary(
                  text: 'UNBLOCK USER',
                  onPressed: () {
                    _updateUserStatus(user['id'], 'approved');
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.green,
                  height: 48,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AppButton.secondary(
                text: 'CLOSE',
                onPressed: () => Navigator.pop(context),
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value ?? 'N/A', style: AppTextStyles.bodyLarge()),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'blocked':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall(
          color: color,
        ).copyWith(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
