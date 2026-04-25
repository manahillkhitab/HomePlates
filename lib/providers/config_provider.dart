import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/models/app_config_model.dart';
import '../utils/constants.dart';

final configProvider = AsyncNotifierProvider<ConfigNotifier, AppConfigModel>(
  ConfigNotifier.new,
);

class ConfigNotifier extends AsyncNotifier<AppConfigModel> {
  Box<AppConfigModel> get _configBox =>
      Hive.box<AppConfigModel>(AppConstants.configBox);

  @override
  Future<AppConfigModel> build() async {
    // Try cloud fetch first
    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select()
          .single();

      final rawChefComm = (response['chef_commission'] as num).toDouble();
      final rawRiderComm = (response['rider_commission'] as num).toDouble();

      final remoteConfig = AppConfigModel(
        baseDeliveryFee: (response['base_delivery_fee'] as num).toDouble(),
        chefCommission: rawChefComm > 1 ? rawChefComm / 100 : rawChefComm,
        riderCommission: rawRiderComm > 1 ? rawRiderComm / 100 : rawRiderComm,
      );

      // Cache locally
      await _configBox.put('current', remoteConfig);
      return remoteConfig;
    } catch (e) {
      // Fallback to local cache
      if (_configBox.isNotEmpty) {
        return _configBox.get('current')!;
      }
      return AppConfigModel(); // Default
    }
  }

  Future<void> updateConfig(AppConfigModel newConfig) async {
    // Optimistic Update
    state = AsyncValue.data(newConfig);

    try {
      // 1. Save Local
      await _configBox.put('current', newConfig);

      // 2. Save Remote
      await Supabase.instance.client
          .from('app_config')
          .update({
            'base_delivery_fee': newConfig.baseDeliveryFee,
            'chef_commission': newConfig.chefCommission,
            'rider_commission': newConfig.riderCommission,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', 1);
    } catch (e) {
      // Revert on error? Or just log. For admin, showing error is better.
      debugPrint('Config sync error: $e');
      // state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBaseDeliveryFee(double fee) async {
    final current = state.value;
    if (current == null) return;
    await updateConfig(current.copyWith(baseDeliveryFee: fee));
  }

  Future<void> updateChefCommission(double commission) async {
    final current = state.value;
    if (current == null) return;
    await updateConfig(current.copyWith(chefCommission: commission));
  }

  Future<void> updateRiderCommission(double commission) async {
    final current = state.value;
    if (current == null) return;
    await updateConfig(current.copyWith(riderCommission: commission));
  }
}
