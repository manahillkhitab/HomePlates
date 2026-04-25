import 'package:flutter/material.dart';
import '../data/local/models/user_model.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final UserModel? user;
  const RoleSelectionScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                user != null ? 'Switch Mode' : 'Join HomePlates as...',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                user != null
                    ? 'Select your target role'
                    : 'Select your role to continue',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RoleCard(
                title: 'Customer',
                description: 'Order healthy, homemade food',
                icon: Icons.restaurant,
                role: UserRole.customer,
                onTap: () => _handleRoleSelected(context, UserRole.customer),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Home Chef',
                description: 'Share your recipes and earn',
                icon: Icons.outdoor_grill,
                role: UserRole.chef,
                onTap: () => _handleRoleSelected(context, UserRole.chef),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Rider',
                description: 'Deliver joy and earn on the go',
                icon: Icons.delivery_dining,
                role: UserRole.rider,
                onTap: () => _handleRoleSelected(context, UserRole.rider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRoleSelected(BuildContext context, UserRole role) {
    if (user != null) {
      Navigator.pop(context, role);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(selectedRole: role),
        ),
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final UserRole role;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.mutedSaffron.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mutedSaffron.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.mutedSaffron, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: AppTheme.lightText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.warmCharcoal),
          ],
        ),
      ),
    );
  }
}
