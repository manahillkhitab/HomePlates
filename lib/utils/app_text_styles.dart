import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography system for HomePlates
/// Uses Outfit font with clear hierarchy
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Display styles - Hero titles, major headings
  static TextStyle displayLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.3,
        color: color,
      );

  // Heading styles - Section headers, card titles
  static TextStyle headingLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0,
        color: color,
      );

  // Body styles - Primary content
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
        color: color,
      );

  // Label styles - Buttons, chips, badges
  static TextStyle labelLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.8,
        color: color,
      );

  // Caption styles - Timestamps, helper text
  static TextStyle caption({Color? color}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        height: 1.4,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle overline({Color? color}) => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.6,
        letterSpacing: 1.5,
        color: color,
      );

  // Button text
  static TextStyle button({Color? color}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.43,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle buttonLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.5,
        color: color,
      );
}
