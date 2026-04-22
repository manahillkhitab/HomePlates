import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const String _boxName = 'settingsBox';
  static const String _key = 'selected_locale';

  Future<void> _loadLocale() async {
    final box = await Hive.openBox(_boxName);
    final localeCode = box.get(_key, defaultValue: 'en');
    state = Locale(localeCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, locale.languageCode);
  }
}
