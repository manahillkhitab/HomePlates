import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography system for HomePlates
/// Uses Outfit font with clear hierarchy
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Display styles - Hero titles, major headings
  static TextStyle displayLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: fontWeight ?? FontWeight.w900,
    height: 1.2,
    letterSpacing: letterSpacing ?? -0.5,
    color: color,
  );

  static TextStyle displayMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: fontWeight ?? FontWeight.w800,
    height: 1.25,
    letterSpacing: letterSpacing ?? -0.3,
    color: color,
  );

  // Heading styles - Section headers, card titles
  static TextStyle headingLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: fontWeight ?? FontWeight.w700,
    height: 1.3,
    letterSpacing: letterSpacing ?? 0,
    color: color,
  );

  static TextStyle headingMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: fontWeight ?? FontWeight.w600,
    height: 1.3,
    letterSpacing: letterSpacing ?? 0,
    color: color,
  );

  static TextStyle headingSmall({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: fontWeight ?? FontWeight.w600,
    height: 1.35,
    letterSpacing: letterSpacing ?? 0,
    color: color,
  );

  // Body styles - Primary content
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: fontWeight ?? FontWeight.w400,
    height: 1.5,
    letterSpacing: letterSpacing ?? 0.15,
    color: color,
  );

  static TextStyle bodyMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: fontWeight ?? FontWeight.w400,
    height: 1.5,
    letterSpacing: letterSpacing ?? 0.25,
    color: color,
  );

  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: fontWeight ?? FontWeight.w400,
    height: 1.5,
    letterSpacing: letterSpacing ?? 0.4,
    color: color,
  );

  // Label styles - Buttons, chips, badges
  static TextStyle labelLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: fontWeight ?? FontWeight.w600,
    height: 1.4,
    letterSpacing: letterSpacing ?? 0.5,
    color: color,
  );

  static TextStyle labelMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: fontWeight ?? FontWeight.w600,
    height: 1.4,
    letterSpacing: letterSpacing ?? 0.5,
    color: color,
  );

  static TextStyle labelSmall({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: fontWeight ?? FontWeight.w600,
    height: 1.4,
    letterSpacing: letterSpacing ?? 0.8,
    color: color,
  );

  // Caption styles - Timestamps, helper text
  static TextStyle caption({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: fontWeight ?? FontWeight.w300,
    height: 1.4,
    letterSpacing: letterSpacing ?? 0.4,
    color: color,
  );

  static TextStyle overline({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: fontWeight ?? FontWeight.w500,
    height: 1.6,
    letterSpacing: letterSpacing ?? 1.5,
    color: color,
  );

  // Button text
  static TextStyle button({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: fontWeight ?? FontWeight.w700,
    height: 1.43,
    letterSpacing: letterSpacing ?? 0.5,
    color: color,
  );

  static TextStyle buttonLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: fontWeight ?? FontWeight.w700,
    height: 1.25,
    letterSpacing: letterSpacing ?? 0.5,
    color: color,
  );
}
