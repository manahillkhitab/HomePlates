import 'package:hive/hive.dart';
import 'cart_model.dart';

part 'cart_summary.g.dart';

@HiveType(typeId: 23)
class CartSummary extends HiveObject {
  @HiveField(0)
  final List<CartItem> items;

  @HiveField(1)
  final String? chefId;

  @HiveField(2)
  final DateTime? scheduledTime;

  CartSummary({
    required this.items,
    this.chefId,
    this.scheduledTime,
  });

  double get total => items.fold(0, (sum, item) {
    final optionsPrice = item.selectedOptions.fold(0.0, (s, o) => s + o.price);
    return sum + ((item.price + optionsPrice) * item.quantity);
  });
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
