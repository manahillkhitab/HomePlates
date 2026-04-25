import 'package:flutter/material.dart';

class AppTheme {
  // Exact HomePlates brand color scheme
  static const Color offWhite = Color(
    0xFFFDFBF7,
  ); // Warm cream tone to match logo background
  static const Color warmCharcoal = Color(
    0xFF1F2933,
  ); // Warm Charcoal for "Home"
  static const Color mutedSaffron = Color(
    0xFFF4B740,
  ); // Muted Saffron for "Plates" and accents
  static const Color lightText = Color(0xFF757575); // Light gray text
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards

  // Legacy aliases for backward compatibility
  static const Color primaryBeige = offWhite;
  static const Color accentGold = mutedSaffron;
  static const Color primaryGold = mutedSaffron;
  static const Color darkText = warmCharcoal;
  static const Color buttonGold = mutedSaffron;
  static const Color darkCard = Color(0xFF2D3748);
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkAccent = Color(0xFF4A5568);
  static const Color accentSaffron = Color(0xFFFF9E44);

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 14.0;

  // Animations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 400);

  // Shadows
  static List<BoxShadow> shadowSm(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: offWhite,
      scaffoldBackgroundColor: offWhite,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: warmCharcoal),
        titleTextStyle: TextStyle(
          color: warmCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: warmCharcoal,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: warmCharcoal,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: warmCharcoal),
        bodyMedium: TextStyle(fontSize: 14, color: lightText),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mutedSaffron,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mutedSaffron, width: 2),
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: mutedSaffron,
        primary: mutedSaffron,
        secondary: mutedSaffron,
        surface: cardBackground,
      ),
    );
  }
}
