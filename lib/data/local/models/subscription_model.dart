import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 18)
enum SubscriptionTier {
  @HiveField(0)
  free,
  @HiveField(1)
  silver,
  @HiveField(2)
  gold,
}

@HiveType(typeId: 19)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final SubscriptionTier tier;
  @HiveField(2)
  final double commissionRate;
  @HiveField(3)
  final double monthlyPrice;
  @HiveField(4)
  final List<String> perks;

  SubscriptionModel({
    required this.id,
    required this.tier,
    required this.commissionRate,
    required this.monthlyPrice,
    required this.perks,
  });

  static List<SubscriptionModel> get availableTiers => [
    SubscriptionModel(
      id: 'free',
      tier: SubscriptionTier.free,
      commissionRate: 0.15,
      monthlyPrice: 0,
      perks: ['Standard visibility', '15% commission'],
    ),
    SubscriptionModel(
      id: 'silver',
      tier: SubscriptionTier.silver,
      commissionRate: 0.10,
      monthlyPrice: 500,
      perks: ['Enhanced visibility', '10% commission', 'Promoted badge'],
    ),
    SubscriptionModel(
      id: 'gold',
      tier: SubscriptionTier.gold,
      commissionRate: 0.05,
      monthlyPrice: 1500,
      perks: ['Priority search', '5% commission', 'Featured category'],
    ),
  ];
}
