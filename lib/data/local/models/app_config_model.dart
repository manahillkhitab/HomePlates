import 'package:hive/hive.dart';

part 'app_config_model.g.dart';

@HiveType(typeId: 21)
class AppConfigModel extends HiveObject {
  @HiveField(0)
  final double chefCommission; // e.g., 0.1 for 10%

  @HiveField(1)
  final double riderCommission; // e.g., 0.1 for 10%

  @HiveField(2)
  final double baseDeliveryFee;

  @HiveField(3)
  final double platformServiceFee;

  AppConfigModel({
    this.chefCommission = 0.1,
    this.riderCommission = 0.1,
    this.baseDeliveryFee = 50.0,
    this.platformServiceFee = 10.0,
  });

  AppConfigModel copyWith({
    double? chefCommission,
    double? riderCommission,
    double? baseDeliveryFee,
    double? platformServiceFee,
  }) {
    return AppConfigModel(
      chefCommission: chefCommission ?? this.chefCommission,
      riderCommission: riderCommission ?? this.riderCommission,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      platformServiceFee: platformServiceFee ?? this.platformServiceFee,
    );
  }
}
