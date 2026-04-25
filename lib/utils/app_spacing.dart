/// Centralized spacing system for HomePlates
/// Provides consistent spacing scale across the app
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing scale (8dp grid system)
  static const double xs = 4.0; // Extra small - Tight spacing
  static const double sm = 8.0; // Small - Compact spacing
  static const double md = 16.0; // Medium - Default spacing
  static const double lg = 24.0; // Large - Section spacing
  static const double xl = 32.0; // Extra large - Major sections
  static const double xxl = 48.0; // Extra extra large - Hero sections

  // Specific use cases
  static const double cardPadding = md;
  static const double screenPadding = md;
  static const double sectionGap = lg;
  static const double itemGap = sm;
  static const double tinyGap = xs;
}
