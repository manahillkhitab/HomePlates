import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class ThemeController {
  final Box _settingsBox = Hive.box(AppConstants.settingsBox);

  // Singleton
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  /// Check if dark mode is enabled
  bool get isDarkMode =>
      _settingsBox.get(AppConstants.themeKey, defaultValue: false);

  /// Toggle theme and save preference
  Future<void> toggleTheme(bool isDark) async {
    await _settingsBox.put(AppConstants.themeKey, isDark);
  }

  /// Listen to theme changes
  ValueListenable<Box> get themeListenable =>
      _settingsBox.listenable(keys: [AppConstants.themeKey]);
}
