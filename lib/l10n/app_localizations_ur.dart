// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ہوم پلیٹس';

  @override
  String welcomeBack(String name) {
    return 'خوش آمدید، $name';
  }

  @override
  String get availableToday => 'آج دستیاب ہے';

  @override
  String get featuredToday => 'آج کی خاص ڈشز';

  @override
  String get myOrders => 'میرے آرڈرز';

  @override
  String get wallet => 'والیٹ';

  @override
  String get settings => 'ترتیبات';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get payout => 'ادائیگی';

  @override
  String get totalPrice => 'کل قیمت';

  @override
  String get addToCart => 'ٹوکری میں ڈالیں';

  @override
  String get checkout => 'چیک آؤٹ';
}
