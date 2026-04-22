import 'package:hive/hive.dart';
import '../models/promo_model.dart';
import '../models/dish_model.dart';
import '../../../utils/constants.dart';

class SeedService {
  static Future<void> seedPhase7() async {
    final promoBox = Hive.box<PromoModel>('promoBox');
    if (promoBox.isEmpty) {
      await promoBox.addAll([
        PromoModel(
          id: 'welcome10',
          code: 'WELCOME10',
          discountPercentage: 0.1,
          maxDiscount: 200,
          minOrderAmount: 500,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        ),
        PromoModel(
          id: 'feast20',
          code: 'FEAST20',
          discountPercentage: 0.2,
          maxDiscount: 500,
          minOrderAmount: 1500,
          expiryDate: DateTime.now().add(const Duration(days: 15)),
        ),
      ]);
    }

    // Mark random dishes as promoted for demo
    final dishBox = Hive.box<DishModel>(AppConstants.dishBox);
    if (dishBox.isNotEmpty) {
      final values = dishBox.values.toList();
      for (int i = 0; i < (values.length > 3 ? 3 : values.length); i++) {
        await dishBox.put(values[i].id, values[i].copyWith(isPromoted: true));
      }
    }
  }
}
