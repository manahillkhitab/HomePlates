import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/models/user_model.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final UserModel? user; // If provided, acts as Switcher
  const RoleSelectionScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Mesh Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF0F1115), const Color(0xFF1A1D23)]
                    : [const Color(0xFFF8F9FA), Colors.white],
                ),
              ),
            ),
          ),
          // Accent glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGold.withOpacity(isDark ? 0.05 : 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 60,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    user != null ? 'Select Context' : 'HomePlates',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.warmCharcoal,
                      letterSpacing: -2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user != null ? 'Switch to another role' : 'Homemade joy served at your door',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.warmCharcoal.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // CUSTOMER CARD (Always available)
                  if (user == null || user!.hasRole(UserRole.customer))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoleCard(
                        title: user != null ? 'Continue as Customer' : 'Customer',
                        description: 'Order healthy, homemade food',
                        icon: Icons.restaurant_rounded,
                        role: UserRole.customer,
                        isActive: user?.role == UserRole.customer,
                        onTap: () => _handleRoleSelection(context, UserRole.customer),
                      ),
                    ),

                  // CHEF CARD
                  if (user == null || user!.hasRole(UserRole.chef))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoleCard(
                        title: user != null ? 'Manage Kitchen' : 'Home Chef',
                        description: 'Share your recipes and earn',
                        icon: Icons.outdoor_grill_rounded,
                        role: UserRole.chef,
                        isActive: user?.role == UserRole.chef,
                        status: user != null && user!.rolesData['chef'] is String ? user!.rolesData['chef'] : null,
                        onTap: () => _handleRoleSelection(context, UserRole.chef),
                      ),
                    ),

                  // RIDER CARD
                  if (user == null || user!.hasRole(UserRole.rider))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoleCard(
                        title: user != null ? 'Start Riding' : 'Rider',
                        description: 'Deliver joy and earn on the go',
                        icon: Icons.delivery_dining_rounded,
                        role: UserRole.rider,
                        isActive: user?.role == UserRole.rider,
                        status: user != null && user!.rolesData['rider'] is String ? user!.rolesData['rider'] : null,
                        onTap: () => _handleRoleSelection(context, UserRole.rider),
                      ),
                    ),

                  const Spacer(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRoleSelection(BuildContext context, UserRole role) {
    if (user != null) {
      // Authenticated Mode: Switch Role
      Navigator.pop(context, role); // Return selected role
    } else {
      // Guest Mode: Navigate to Login
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(selectedRole: role),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final UserRole role;
  final bool isActive;
  final String? status;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.role,
    required this.onTap,
    this.isActive = false,
    this.status,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: AppTheme.primaryGold.withOpacity(_isPressed ? 0.4 : 0.05),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (_isPressed)
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGold.withValues(alpha: 0.2),
                      AppTheme.primaryGold.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.primaryGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.warmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : AppTheme.warmCharcoal.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.primaryGold,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
