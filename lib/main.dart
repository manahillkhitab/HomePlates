import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/local/services/seed_service.dart';
import 'data/local/sample_model.dart';
import 'data/local/models/user_model.dart';
import 'data/local/models/dish_model.dart';
import 'data/local/models/order_model.dart';
import 'data/local/models/review_model.dart';
import 'data/local/models/transaction_model.dart';
import 'data/local/models/notification_model.dart';
import 'data/local/models/cart_model.dart';
import 'data/local/models/cart_summary.dart';
import 'data/local/models/subscription_model.dart';
import 'data/local/models/dish_option.dart';
import 'data/local/models/app_config_model.dart';
import 'providers/locale_provider.dart';
import 'data/local/models/promo_model.dart';
import 'data/local/services/notification_service.dart';
import 'data/local/services/sync_service.dart';
import 'data/local/models/message_model.dart';
import 'data/local/models/post_model.dart';
import 'controllers/theme_controller.dart';
import 'screens/role_selection_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Register Hive Adapters
  Hive.registerAdapter(SampleModelAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(UserStatusAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(DishModelAdapter());
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(RefundStatusAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  Hive.registerAdapter(ReviewModelAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TransactionStatusAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  Hive.registerAdapter(OrderItemAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(CartSummaryAdapter());
  Hive.registerAdapter(AppConfigModelAdapter());
  Hive.registerAdapter(PromoModelAdapter());
  Hive.registerAdapter(SubscriptionTierAdapter());
  Hive.registerAdapter(SubscriptionModelAdapter());
  Hive.registerAdapter(DishOptionAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(PostModelAdapter());

  // Open all Hive boxes BEFORE runApp()
  await Hive.openBox<SampleModel>(HiveBoxes.sampleBox);
  await Hive.openBox<UserModel>(AppConstants.userBox);
  await Hive.openBox<DishModel>(AppConstants.dishBox);
  await Hive.openBox<OrderModel>(AppConstants.orderBox);
  await Hive.openBox<ReviewModel>(AppConstants.reviewBox);
  await Hive.openBox<TransactionModel>(AppConstants.transactionBox);
  await Hive.openBox<NotificationModel>(AppConstants.notificationBox);
  await Hive.openBox<CartSummary>(AppConstants.cartBox);
  await Hive.openBox<AppConfigModel>(AppConstants.configBox);
  await Hive.openBox<PromoModel>('promoBox');
  await Hive.openBox<MessageModel>(AppConstants.messageBox);
  await Hive.openBox<PostModel>(AppConstants.postBox);

  // Open Settings Box
  await Hive.openBox(AppConstants.settingsBox);

  // Seed Phase 7 data for demo
  await SeedService.seedPhase7();

  // Initialize Sync Service (Auto Sync)
  final syncService = SyncService();
  syncService.startAutoSync();

  // Run the app
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    
    return ValueListenableBuilder(
      valueListenable: ThemeController().themeListenable,
      builder: (context, box, widget) {
        final isDark = ThemeController().isDarkMode;
        return MaterialApp(
          title: 'HomePlates',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          // localizationsDelegates: [
          //   AppLocalizations.delegate,
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          // supportedLocales: const [Locale('en')],
          home: const SplashScreen(),
        );
      },
    );
  }
}
