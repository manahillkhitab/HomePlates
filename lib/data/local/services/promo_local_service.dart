import 'package:hive/hive.dart';
import '../models/promo_model.dart';

class PromoLocalService {
  Box<PromoModel> get _promoBox => Hive.box<PromoModel>('promoBox');

  Future<void> savePromo(PromoModel promo) async {
    await _promoBox.put(promo.id, promo);
  }

  PromoModel? getPromoByCode(String code) {
    try {
      return _promoBox.values.firstWhere(
        (p) => p.code.toUpperCase() == code.toUpperCase() && p.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  List<PromoModel> getAllPromos() {
    return _promoBox.values.toList();
  }

  Future<void> updatePromoUsage(String promoId) async {
    final promo = _promoBox.get(promoId);
    if (promo != null) {
      await _promoBox.put(
        promoId,
        promo.copyWith(
          usedCount: promo.usedCount + 1,
          isActive: (promo.usedCount + 1) < promo.usageLimit,
        ),
      );
    }
  }

  Future<void> deletePromo(String id) async {
    await _promoBox.delete(id);
  }
}
