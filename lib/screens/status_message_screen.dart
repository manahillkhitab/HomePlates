import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/local/models/user_model.dart';
import '../utils/app_theme.dart';
import 'role_selection_screen.dart';
import 'customer_home_screen.dart';
import 'chef_home_screen.dart';
import 'rider_home_screen.dart';
import '../utils/routes.dart';

class StatusMessageScreen extends ConsumerWidget {
  final UserStatus status;
  
  const StatusMessageScreen({
    super.key, 
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;

    // Listen for status changes to navigate automatically
    ref.listen(authProvider, (previous, next) {
      final nextUser = next.value;
      if (nextUser != null && nextUser.status == UserStatus.approved) {
        Widget home;
        switch (nextUser.role) {
          case UserRole.customer: home = CustomerHomeScreen(); break;
          case UserRole.chef: home = ChefHomeScreen(); break;
          case UserRole.rider: home = RiderHomeScreen(); break;
          default: home = const RoleSelectionScreen();
        }
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => home));
      }
    });

    // Use current user status if available, fallback to passed status
    final currentStatus = user?.status ?? status;
    
    String title;
    String message;
    IconData icon;
    Color color;

    switch (currentStatus) {
      case UserStatus.pending:
        title = 'Approval Pending';
        message = 'Your application is being reviewed by our team. Please check back in 24-48 hours.';
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        break;
      case UserStatus.rejected:
        title = 'Application Rejected';
        message = 'We regret to inform you that your application was not approved. Contact support for details.';
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      case UserStatus.blocked:
        title = 'Account Blocked';
        message = 'Your account has been suspended for violating our terms of service.';
        icon = Icons.block_rounded;
        color = Colors.redAccent;
        break;
      default:
        title = 'Welcome';
        message = 'Preparing your experience...';
        icon = Icons.check_circle_rounded;
        color = Colors.green;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: color),
            ),
            const SizedBox(height: 48),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppTheme.warmCharcoal.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).reloadUser(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.warmCharcoal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('REFRESH STATUS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _handleLogout(context, ref),
              child: Text(
                'LOGOUT',
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
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
