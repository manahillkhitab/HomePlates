import 'package:flutter/material.dart';
import '../data/local/models/user_model.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'customer_home_screen.dart';
import 'chef_home_screen.dart';
import 'rider_home_screen.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'status_message_screen.dart';
import 'onboarding_screen.dart';
import 'admin_dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    _timer = Timer(const Duration(seconds: AppConstants.splashDuration), () {
      if (mounted) {
        final user = ref.read(authProvider).value;
        
        Widget nextScreen;
        
        if (user != null && user.isLoggedIn) {
          if (user.status != UserStatus.approved) {
            nextScreen = StatusMessageScreen(status: user.status);
          } else {
            // If logged in and approved, go to the respective role home
            switch (user.role) {
              case UserRole.customer:
                nextScreen = CustomerHomeScreen();
                break;
              case UserRole.chef:
                nextScreen = ChefHomeScreen();
                break;
              case UserRole.rider:
                nextScreen = RiderHomeScreen();
                break;
              case UserRole.admin:
                nextScreen = AdminDashboardScreen();
                break;
              default:
                nextScreen = const RoleSelectionScreen();
            }
          }
        } else {
          // Check if onboarding seen
          bool hasSeenOnboarding = false;
          try {
            final settingsBox = Hive.box(AppConstants.settingsBox);
            hasSeenOnboarding = settingsBox.get('hasSeenOnboarding', defaultValue: false);
          } catch (e) {
            debugPrint('Hive box not open or accessible: $e');
          }
          
          if (!hasSeenOnboarding) {
            nextScreen = const OnboardingScreen();
          } else {
            nextScreen = const RoleSelectionScreen();
          }
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.03 : 0.05,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: 150,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemBuilder: (context, index) => const Icon(Icons.restaurant_menu, size: 20),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 80,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        );
                      },
                    ),
                ),
                const SizedBox(height: 32),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Home',
                        style: GoogleFonts.outfit(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.warmCharcoal,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Plates',
                        style: GoogleFonts.outfit(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGold,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HOMEMADE JOY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryGold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
