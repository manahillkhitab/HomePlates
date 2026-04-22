import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/theme_controller.dart';
import '../providers/auth_provider.dart';
import '../data/local/models/user_model.dart';
import '../utils/app_theme.dart';
import '../providers/locale_provider.dart';
import 'role_selection_screen.dart';
import 'splash_screen.dart';
import '../providers/dish_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/earnings_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = ThemeController();
    final user = ref.watch(authProvider).value;
    
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
              'Profile & Config',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryGold, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                                backgroundImage: user?.profileImageUrl.isNotEmpty == true
                                    ? (user!.profileImageUrl.startsWith('http')
                                        ? NetworkImage(user.profileImageUrl)
                                        : FileImage(File(user.profileImageUrl)) as ImageProvider)
                                    : null,
                                child: user?.profileImageUrl.isNotEmpty == true 
                                    ? null 
                                    : const Icon(Icons.restaurant_rounded, color: AppTheme.primaryGold, size: 40),
                              ),
                            ),
                            if (user?.role == UserRole.chef)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _pickImage(context, ref, user!),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.warmCharcoal),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'Guest User',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.role.name.toUpperCase() ?? 'GUEST',
                            style: GoogleFonts.outfit(
                              color: AppTheme.primaryGold, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 10, 
                              letterSpacing: 2
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildProfileInfo(Icons.alternate_email_rounded, user?.email ?? '-'),
                        _buildProfileInfo(Icons.phone_iphone_rounded, user?.phone ?? '-'),
                        _buildProfileInfo(Icons.map_rounded, user?.address ?? '-'),
                        
                        // Chef Specific Information
                        if (user?.role == UserRole.chef) ...[
                          _buildProfileInfo(Icons.storefront_rounded, user?.kitchenName.isNotEmpty == true ? user!.kitchenName : 'Private Kitchen'),
                          if (user?.categories.isNotEmpty == true)
                            _buildProfileInfo(Icons.auto_awesome_mosaic_rounded, user!.categories.join(', ')),
                        ],

                        // Rider Specific Information
                        if (user?.role == UserRole.rider) ...[
                          _buildProfileInfo(Icons.electric_moped_rounded, user?.vehicleType ?? 'Walker'),
                          _buildProfileInfo(Icons.confirmation_number_rounded, user?.vehicleNumber.isNotEmpty == true ? user!.vehicleNumber : 'N/A'),
                        ],

                        _buildProfileInfo(Icons.verified_user_rounded, user?.termsAccepted == true ? 'Verified Account' : 'Pending Verification', isLast: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'ACCOUNT ACCESS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      fontSize: 11, 
                      letterSpacing: 2, 
                      color: AppTheme.primaryGold.withValues(alpha: 0.6)
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Switch Role Tile
                  if (user?.isAdmin == false)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text('Switch Role', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        subtitle: Text('Change your current app mode', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () async {
                          // Open Switcher
                          if (user != null) {
                            final selectedRole = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoleSelectionScreen(user: user),
                              ),
                            );
                            
                            if (selectedRole != null && selectedRole is UserRole) {
                              if (selectedRole != user.role) {
                                 // 1. Invalidate all sensitive providers to clear data
                                 ref.invalidate(dishProvider);
                                 ref.invalidate(orderProvider);
                                 // ref.invalidate(walletProvider); // Family provider, hard to invalidate all? NO, invalidate the family
                                 // Just invalidating the specific user's provider might be needed if we knew the ID, but user ID is same.
                                 // However, the provider family builds based on ID. Since ID is same, state persists.
                                 // So we must invalidate using the user ID.
                                 ref.invalidate(walletProvider(user.id));
                                 ref.invalidate(earningsStatsProvider(user.id));
                                 // ref.invalidate(notificationProvider); // If exists
                                 
                                 // 2. Perform Switch
                                 await ref.read(authProvider.notifier).switchRole(selectedRole);
                                 
                                 // 3. Reboot App
                                 if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                                      (route) => false,
                                    );
                                 }
                              }
                            }
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 40),
                  Text(
                    'INTERFACE PREFERENCES',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      fontSize: 11, 
                      letterSpacing: 2, 
                      color: AppTheme.primaryGold.withValues(alpha: 0.6)
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dark Mode Toggle
                  ValueListenableBuilder(
                    valueListenable: themeController.themeListenable,
                    builder: (context, box, _) {
                      final currentDark = themeController.isDarkMode;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          title: Text('Premium Dark Theme', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          subtitle: Text('Easy on the eyes, elegant design', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24)),
                          value: currentDark,
                          activeColor: AppTheme.primaryGold,
                          onChanged: (value) => themeController.toggleTheme(value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text('App Language / زبان', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        ref.watch(localeProvider).languageCode == 'en' ? 'English (Current)' : 'Urdu (موجودہ)',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryGold),
                      ),
                      leading: const Icon(Icons.language_rounded, color: AppTheme.primaryGold),
                      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: () => _showLanguagePicker(context, ref),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context, ref),
                      icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
                      label: Text(
                        'LOGOUT', 
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'HOMEPLATES PREMIER',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900, 
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1), 
                            fontSize: 10, 
                            letterSpacing: 2.5
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'VERSION 3.0.0-PRO',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.05), 
                            fontWeight: FontWeight.w700, 
                            fontSize: 10
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryGold.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppTheme.primaryGold.withValues(alpha: 0.03)),
          ),
      ],
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 16),
            ListTile(
              title: Text('English', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              trailing: ref.watch(localeProvider).languageCode == 'en' ? const Icon(Icons.check_circle, color: AppTheme.primaryGold) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Urdu (اردو)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              trailing: ref.watch(localeProvider).languageCode == 'ur' ? const Icon(Icons.check_circle, color: AppTheme.primaryGold) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('ur'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref, UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      // Show loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );

      try {
        final updatedUser = user.copyWith(profileImageUrl: pickedFile.path);
        await ref.read(authProvider.notifier).updateProfile(updatedUser);
        
        if (context.mounted) {
          Navigator.pop(context); // Remove loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitchen logo updated successfully! 🍳')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Remove loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update logo: $e')),
          );
        }
      }
    }
  }
}

