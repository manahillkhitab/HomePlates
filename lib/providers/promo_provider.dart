import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/promo_model.dart';
import '../data/local/services/promo_local_service.dart';

final promoServiceProvider = Provider((ref) => PromoLocalService());

final promoProvider = AsyncNotifierProvider<PromoNotifier, List<PromoModel>>(
  PromoNotifier.new,
);

class PromoNotifier extends AsyncNotifier<List<PromoModel>> {
  @override
  Future<List<PromoModel>> build() async {
    return ref.watch(promoServiceProvider).getAllPromos();
  }

  Future<void> addPromo(PromoModel promo) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(promoServiceProvider).savePromo(promo);
      state = AsyncValue.data(ref.read(promoServiceProvider).getAllPromos());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<PromoModel?> validatePromo(String code, double orderAmount) async {
    final promo = ref.read(promoServiceProvider).getPromoByCode(code);

    if (promo == null) return null;

    // Validate expiry
    if (promo.expiryDate.isBefore(DateTime.now())) return null;

    // Validate min amount
    if (orderAmount < promo.minOrderAmount) return null;

    // Validate usage
    if (promo.usedCount >= promo.usageLimit) return null;

    return promo;
  }

  Future<void> markPromoUsed(String promoId) async {
    await ref.read(promoServiceProvider).updatePromoUsage(promoId);
    state = AsyncValue.data(ref.read(promoServiceProvider).getAllPromos());
  }
}

// State for active promo applied to cart
final appliedPromoProvider = StateProvider<PromoModel?>((ref) => null);
