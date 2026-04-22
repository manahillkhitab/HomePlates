import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/data/local/models/app_config_model.dart';
import 'package:flutter_app/data/local/models/cart_model.dart';
import 'package:flutter_app/data/local/models/cart_summary.dart';
import 'package:flutter_app/data/local/models/dish_model.dart';
import 'package:flutter_app/data/local/models/dish_option.dart';
import 'package:flutter_app/data/local/models/message_model.dart';
import 'package:flutter_app/data/local/models/notification_model.dart';
import 'package:flutter_app/data/local/models/order_model.dart';
import 'package:flutter_app/data/local/models/post_model.dart';
import 'package:flutter_app/data/local/models/promo_model.dart';
import 'package:flutter_app/data/local/models/review_model.dart';
import 'package:flutter_app/data/local/models/subscription_model.dart';
import 'package:flutter_app/data/local/models/transaction_model.dart';
import 'package:flutter_app/data/local/models/user_model.dart';

import 'dart:io';

void main() {
  group('Hive Model Registry Test', () {
    setUp(() async {
      final path = Directory.systemTemp.path;
      Hive.init(path);
    });

    test('Verify unique TypeIDs for all adapters', () {
      final adapters = <TypeAdapter>[
        UserModelAdapter(),         // 3
        DishModelAdapter(),         // 4
        OrderModelAdapter(),        // 6
        ReviewModelAdapter(),       // 25 (Was 7)
        TransactionModelAdapter(),  // 12
        NotificationModelAdapter(), // 13
        CartItemAdapter(),          // 15
        CartSummaryAdapter(),       // 23 (Was 16)
        MessageModelAdapter(),      // 16
        PostModelAdapter(),         // 24 (Was 17)
        AppConfigModelAdapter(),    // 21 (Was 18)
        SubscriptionModelAdapter(), // 19
        PromoModelAdapter(),        // 20
        DishOptionAdapter(),        // 22 (Was 20)
        
        // Enums
        UserRoleAdapter(),          // 2
        UserStatusAdapter(),        // 7
        OrderStatusAdapter(),       // 5
        RefundStatusAdapter(),      // 8
        PaymentMethodAdapter(),     // 17
        TransactionTypeAdapter(),   // 10
        TransactionStatusAdapter(), // 11
        SubscriptionTierAdapter(),  // 18
      ];

      final typeIds = <int>{};
      final duplicates = <int>[];

      for (var adapter in adapters) {
        if (typeIds.contains(adapter.typeId)) {
          duplicates.add(adapter.typeId);
        } else {
          typeIds.add(adapter.typeId);
        }
      }

      print('Registered TypeIDs: $typeIds');
      
      if (duplicates.isNotEmpty) {
        fail('Duplicate TypeIDs found: $duplicates');
      } else {
        print('✅ All TypeIDs are unique.');
      }
    });
  });
}
