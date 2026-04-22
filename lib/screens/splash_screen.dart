import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'customer_home_screen.dart';
import 'chef_home_screen.dart';
import 'rider_home_screen.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../data/local/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Timer(const Duration(seconds: AppConstants.splashDuration), () {
      if (mounted) {
        final authController = AuthController();
        
        Widget nextScreen;
        
        if (authController.isLoggedIn) {
          // If logged in, go to the respective role home
          switch (authController.userRole) {
            case UserRole.customer:
              nextScreen = const CustomerHomeScreen();
              break;
            case UserRole.chef:
              nextScreen = const ChefHomeScreen();
              break;
            case UserRole.rider:
              nextScreen = const RiderHomeScreen();
              break;
            default:
              nextScreen = const RoleSelectionScreen();
          }
        } else {
          // Otherwise go to role selection
          nextScreen = const RoleSelectionScreen();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your custom transparent logo from assets
            Image.asset(
              'assets/images/image.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            // App name
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Home',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2933), // Warm Charcoal
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: 'Plates',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF4B740), // Muted Saffron
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
