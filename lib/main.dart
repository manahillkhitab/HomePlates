import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'data/local/sample_model.dart';
import 'data/local/models/user_model.dart';
import 'data/local/models/dish_model.dart';
import 'data/local/models/order_model.dart';
import 'screens/role_selection_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/chef_home_screen.dart';
import 'screens/rider_home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(SampleModelAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(DishModelAdapter());
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(OrderModelAdapter());

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
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
