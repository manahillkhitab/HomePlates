import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  // Exact HomePlates brand color scheme
  static const Color offWhite = Color(0xFFFDFBF7); // Warm cream tone to match logo background
  static const Color warmCharcoal = Color(0xFF1F2933); // Warm Charcoal for "Home"
  static const Color mutedSaffron = Color(0xFFF4B740); // Muted Saffron for "Plates" and accents
  static const Color lightText = Color(0xFF757575); // Light gray text
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards

  // Legacy aliases for backward compatibility
  static const Color primaryBeige = offWhite;
  static const Color accentGold = mutedSaffron;
  static const Color darkText = warmCharcoal;
  static const Color buttonGold = mutedSaffron;

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
        bodyLarge: TextStyle(
          fontSize: 16,
          color: warmCharcoal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightText,
        ),
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
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
        background: offWhite,
      ),
    );
  }
}
