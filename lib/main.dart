import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'data/local/sample_model.dart';
import 'data/local/models/user_model.dart';
import 'data/local/models/dish_model.dart';
import 'data/local/models/order_model.dart';
import 'data/local/models/enums.dart';
import 'data/local/models/order_item.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(SampleModelAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(UserStatusAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(DishModelAdapter());
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(RefundStatusAdapter());
  Hive.registerAdapter(OrderItemAdapter());

  // Open all Hive boxes BEFORE runApp()
  await Hive.openBox<SampleModel>(HiveBoxes.sampleBox);
  await Hive.openBox<UserModel>(AppConstants.userBox);
  await Hive.openBox<DishModel>(AppConstants.dishBox);
  await Hive.openBox<OrderModel>(AppConstants.orderBox);

  // Run the app
  runApp(const HomePlatesApp());
}

class HomePlatesApp extends StatelessWidget {
  const HomePlatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    );
  }
}
