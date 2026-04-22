// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HomePlates';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get availableToday => 'Available Today';

  @override
  String get featuredToday => 'Featured Today';

  @override
  String get myOrders => 'My Orders';

  @override
  String get wallet => 'Wallet';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get payout => 'Payout';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get checkout => 'Checkout';
}
