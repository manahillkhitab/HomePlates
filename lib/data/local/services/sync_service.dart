import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../../../utils/constants.dart';
import 'supabase_storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _connectivity = Connectivity();
  final _storageService = SupabaseStorageService();
  
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Guards against concurrent sync execution.
  /// Using a Completer instead of a simple bool so callers can await
  /// the in-flight sync if they need to.
  Completer<void>? _syncCompleter;

  /// Check if device is online
  Future<bool> get isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Start automatic synchronization
  void startAutoSync() {
    debugPrint('Starting Auto Sync...');

    // Cancel any existing subscriptions/timers to prevent resource leaks
    // when startAutoSync is called multiple times.
    stopAutoSync();
    
    // 1. Initial Sync
    syncAll();

    // 2. Listen to Connectivity Changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('Network connected. Triggering sync...');
        syncAll();
      }
    });

    // 3. Periodic Sync (every 15 minutes) as fallback/routine
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      debugPrint('Periodic sync trigger...');
      syncAll();
    });
  }

  /// Stop automatic synchronization
  void stopAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Auto Sync stopped.');
  }

  /// Start the sync process.
  /// Returns immediately if a sync is already in progress (prevents
  /// concurrent execution from timer + connectivity + manual triggers).
  Future<void> syncAll() async {
    // FIX #7: Prevent concurrent sync execution
    if (_syncCompleter != null) {
      debugPrint('Sync already in progress, skipping duplicate trigger.');
      return;
    }

    if (!await isOnline) {
      debugPrint('Offline: Skipping sync');
      return;
    }

    _syncCompleter = Completer<void>();
    try {
      debugPrint('Starting Sync Execution...');
      await _syncUsers();
      await _syncDishes();
      await _syncOrders();
      await _syncReviews();
      await _syncTransactions(); // Download-only (server-side authority)
      await _syncNotifications(); // Download-only (server-side authority)
      debugPrint('Sync Execution Complete!');
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  // --- Internals ---

  /// FIX #5: Only sync the currently authenticated user's own profile,
  /// not every user record in the local cache. Uploading other users'
  /// data is a privilege escalation risk (a client could modify another
  /// user's profile fields like is_approved).
  Future<void> _syncUsers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final box = Hive.box<UserModel>(AppConstants.userBox);
    final currentUser = box.get(userId);
    if (currentUser == null) return;

    try {
      await _supabase.from('users').upsert({
        'id': currentUser.id,
        'email': currentUser.email,
        'name': currentUser.name,
        'role': currentUser.role.name,
        'address': currentUser.address,
        'phone_number': currentUser.phone,
        'subscription_tier': currentUser.subscriptionTier.name,
        'profile_image': currentUser.profileImageUrl,
        'is_approved': currentUser.status == UserStatus.approved,
        'is_chef_active': !currentUser.isKitchenClosed,
        'updated_at': currentUser.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error syncing user ${currentUser.id}: $e');
    }
  }

  Future<void> _syncDishes() async {
    final box = Hive.box<DishModel>(AppConstants.dishBox);
    // 1. Upload local to cloud
    for (var dish in box.values) {
      try {
        String? cloudUrl;
        // FIX #3: Check that the local file actually exists before attempting upload.
        // The path may refer to a deleted file or a stale cache entry.
        if (dish.imagePath.isNotEmpty && !dish.imagePath.startsWith('http')) {
          final localFile = File(dish.imagePath);
          if (await localFile.exists()) {
            cloudUrl = await _storageService.uploadFile(
              file: localFile, 
              bucket: 'dish_images', 
              remotePath: _storageService.generateFileName(dish.imagePath, 'dish_${dish.id}')
            );
          } else {
            debugPrint('⚠️ Local image not found for dish ${dish.id}: ${dish.imagePath}');
          }
        }

        await _supabase.from('dishes').upsert({
          'id': dish.id,
          'chef_id': dish.chefId,
          'name': dish.name,
          'description': dish.description,
          'price': dish.price,
          'category': dish.category,
          'image_url': cloudUrl ?? dish.imagePath,
          'likes_count': dish.likesCount,
          'prep_time_minutes': dish.prepTimeMinutes,
          'is_active': dish.isAvailable,
          'updated_at': dish.updatedAt.toIso8601String(),
        });

        if (cloudUrl != null) {
          await box.put(dish.id, dish.copyWith(imagePath: cloudUrl, isSynced: true));
        }
      } catch (e) {
        debugPrint('Error syncing dish ${dish.id}: $e');
      }
    }

    // 2. Download cloud to local (If I am a Chef)
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final remoteDishesBase = await _supabase.from('dishes').select().eq('chef_id', userId);
        for (var dData in remoteDishesBase) {
          if (!box.containsKey(dData['id'])) {
            final remoteDish = DishModel.fromJson(dData);
            await box.put(remoteDish.id, remoteDish);
          }
        }
      } catch (e) {
        debugPrint('Error downloading dishes: $e');
      }
    }
  }

  Future<void> _syncOrders() async {
    final box = Hive.box<OrderModel>(AppConstants.orderBox);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Upload/Sync existing local orders
    for (var order in box.values) {
      try {
        debugPrint('📤 Syncing order ${order.id}...');
        final remoteOrder = await _supabase.from('orders').select('updated_at').eq('id', order.id).maybeSingle();
        if (remoteOrder != null) {
          final remoteUpdatedAt = DateTime.parse(remoteOrder['updated_at']);
          if (remoteUpdatedAt.isAfter(order.updatedAt)) {
             debugPrint('📥 Cloud is newer for ${order.id}, downloading...');
             final fullRemote = await _supabase.from('orders').select().eq('id', order.id).single();
             await box.put(order.id, _mapRemoteToOrder(fullRemote));
             continue;
          }
        }

        debugPrint('🚀 Upserting order ${order.id} to cloud...');
        await _supabase.from('orders').upsert({
          'id': order.id,
          'customer_id': order.customerId,
          'chef_id': order.chefId,
          'dish_id': order.dishId,
          'dish_name': order.dishName,
          'dish_image_path': order.dishImagePath,
          'price_per_item': order.pricePerItem,
          'quantity': order.quantity,
          'total_price': order.totalPrice,
          'status': order.status.name,
          'rider_id': order.riderId,
          'cancel_reason': order.cancelReason,
          'refund_status': order.refundStatus.name,
          'created_at': order.createdAt.toIso8601String(),
          'updated_at': order.updatedAt.toIso8601String(),
          'delivery_address': order.deliveryAddress,
          'notes': order.notes,
          'delivery_fee': order.deliveryFee,
          'chef_name': order.chefName,
          'chef_address': order.chefAddress,
          'chef_phone': order.chefPhone,
          'customer_name': order.customerName,
          'customer_phone': order.customerPhone,
          'items': order.items?.map((e) => {
            'dishId': e.dishId,
            'name': e.name,
            'price': e.price,
            'quantity': e.quantity,
            'imagePath': e.imagePath,
          }).toList() ?? [],
        });
        
        if (!order.isSynced) {
          await box.put(order.id, order.copyWith(isSynced: true));
        }
        debugPrint('✅ Order ${order.id} synced successfully!');
      } catch (e) {
        debugPrint('❌ FAILED to sync order ${order.id}: $e');
      }
    }

    // 2. Download missing history (Orders where I am Customer, Chef, or Rider)
    try {
      debugPrint('📥 Downloading order history for user $userId...');
      
      // Get user role to see if we should fetch available missions
      final userBox = Hive.box<UserModel>(AppConstants.userBox);
      final currentUser = userBox.get(userId);
      final isRider = currentUser?.role == UserRole.rider;

      String filter = 'customer_id.eq.$userId,chef_id.eq.$userId,rider_id.eq.$userId';
      if (isRider) {
        filter += ',status.eq.ready';
      }
      
      final remoteHistory = await _supabase.from('orders')
          .select()
          .or(filter);
      
      for (var remoteData in remoteHistory) {
        if (!box.containsKey(remoteData['id'])) {
          final order = _mapRemoteToOrder(remoteData);
          await box.put(order.id, order);
        }
      }
      debugPrint('✅ History/Available download complete: ${remoteHistory.length} orders found.');
    } catch (e) {
      debugPrint('❌ FAILED to download order history: $e');
    }
  }

  OrderModel _mapRemoteToOrder(Map<String, dynamic> remote) {
    return OrderModel(
      id: remote['id'],
      customerId: remote['customer_id'],
      chefId: remote['chef_id'],
      dishId: remote['dish_id'],
      dishName: remote['dish_name'],
      dishImagePath: remote['dish_image_path'] ?? '',
      quantity: remote['quantity'],
      pricePerItem: (remote['price_per_item'] as num).toDouble(),
      totalPrice: (remote['total_price'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == remote['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(remote['created_at']),
      updatedAt: DateTime.parse(remote['updated_at']),
      riderId: remote['rider_id'],
      isSynced: true,
      cancelReason: remote['cancel_reason'],
      refundStatus: RefundStatus.values.firstWhere(
        (e) => e.name == remote['refund_status'],
        orElse: () => RefundStatus.none,
      ),
      deliveryAddress: remote['delivery_address'],
      notes: remote['notes'],
      deliveryFee: (remote['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      chefName: remote['chef_name'],
      chefAddress: remote['chef_address'],
      chefPhone: remote['chef_phone'],
      customerName: remote['customer_name'],
      customerPhone: remote['customer_phone'],
      items: remote['items'] != null ? (remote['items'] as List).map((i) => OrderItem(
        dishId: i['dishId'],
        name: i['name'],
        price: (i['price'] as num).toDouble(),
        quantity: i['quantity'],
        imagePath: i['imagePath'],
      )).toList() : null,
    );
  }

  Future<void> _syncReviews() async {
    final box = Hive.box<ReviewModel>(AppConstants.reviewBox);
     for (var review in box.values) {
       try {
        await _supabase.from('reviews').upsert({
          'id': review.id,
          'customer_id': review.customerId,
          'chef_id': review.chefId,
          'dish_id': review.dishId,
          'order_id': review.orderId,
          'rating': review.rating,
          'comment': review.comment,
          'created_at': review.createdAt.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error syncing review ${review.id}: $e');
      }
    }
  }

  /// FIX #2: Comment corrected — transactions are download-only.
  /// Upload is intentionally disabled as a security measure: financial
  /// transactions must only be created/modified on the server side to
  /// prevent clients from fabricating or altering transaction records.
  Future<void> _syncTransactions() async {
    final box = Hive.box<TransactionModel>(AppConstants.transactionBox);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Upload is DISABLED (Security: Server-Side Authority Only).
    // Transactions must be created by server-side logic (Edge Functions,
    // database triggers, or admin actions) — never by the client.

    // Download cloud to local (for status updates like 'completed' by admin)
    try {
      final remoteTx = await _supabase.from('transactions').select().eq('user_id', userId);
      for (var txData in remoteTx) {
        final tx = TransactionModel(
          id: txData['id'],
          userId: txData['user_id'],
          amount: (txData['amount'] as num).toDouble(),
          type: TransactionType.values.firstWhere((e) => e.name == txData['type']),
          status: TransactionStatus.values.firstWhere((e) => e.name == txData['status']),
          orderId: txData['order_id'],
          createdAt: DateTime.parse(txData['created_at']),
        );
        await box.put(tx.id, tx);
      }
    } catch (e) {
      debugPrint('Error downloading transactions: $e');
    }
  }

  /// FIX #1: Notifications are now download-only, matching transactions.
  /// Client-side upload is disabled because the previous implementation
  /// allowed any client to upsert notifications with an arbitrary user_id,
  /// effectively letting an attacker send fake notifications to any user.
  /// Notifications should be created server-side (e.g., database triggers
  /// on order status changes, Edge Functions for marketing pushes).
  Future<void> _syncNotifications() async {
    final box = Hive.box<NotificationModel>(AppConstants.notificationBox);
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Upload is DISABLED (Security: prevents targeting arbitrary users).
    // Notifications must be created server-side via database triggers or
    // Edge Functions — never by the client.

    // Download cloud to local (My Notifications)
    try {
      final remoteNotifications = await _supabase.from('notifications')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);
          
      for (var nData in remoteNotifications) {
        final notification = NotificationModel(
          id: nData['id'],
          title: nData['title'],
          body: nData['body'],
          type: nData['type'],
          relatedId: nData['related_id'],
          isRead: nData['is_read'],
          createdAt: DateTime.parse(nData['created_at']),
          userId: nData['user_id'],
        );
        await box.put(notification.id, notification);
      }
    } catch (e) {
      debugPrint('Error downloading notifications: $e');
    }
  }

  /// FIX #4: Atomic conditional update eliminates the TOCTOU race condition.
  /// Instead of SELECT-then-UPDATE (where another rider could claim between
  /// the two queries), we perform a single UPDATE with a WHERE clause that
  /// ensures rider_id is still null. If zero rows are affected, someone
  /// else already claimed it.
  ///
  /// FIX #6: A single timestamp is captured once and used for both the
  /// cloud update and the local Hive write, ensuring consistency.
  Future<String?> claimOrder(String orderId, String riderId) async {
    if (!await isOnline) return 'Offline: Cannot claim order while disconnected';
    debugPrint('🚀 CLAIM ATTEMPT: orderId=$orderId, riderId=$riderId');
    try {
      // FIX #6: Single timestamp for both cloud and local
      final claimTimestamp = DateTime.now().toUtc();

      // FIX #4: Atomic claim — one UPDATE with conditions instead of
      // SELECT-then-UPDATE. The .isFilter('rider_id', null) ensures we only
      // succeed if no other rider has claimed it yet.
      final response = await _supabase.from('orders')
          .update({
            'status': OrderStatus.pickedUp.name,
            'rider_id': riderId,
            'updated_at': claimTimestamp.toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', OrderStatus.ready.name) // Only claim orders in 'ready' status
          .isFilter('rider_id', null) // Only if no rider has claimed it yet
          .select();

      debugPrint('📝 ATOMIC CLAIM RESPONSE: $response');

      if (response.isEmpty) {
        // The UPDATE matched zero rows. Either:
        // - The order doesn't exist
        // - It's no longer in 'ready' status
        // - Another rider already claimed it
        return 'This order is no longer available — it may have been claimed by another rider. 🏃💨';
      }

      // Success — update local cache with the same timestamp
      final box = Hive.box<OrderModel>(AppConstants.orderBox);
      final localOrder = box.get(orderId);
      if (localOrder != null) {
        await box.put(orderId, localOrder.copyWith(
          status: OrderStatus.pickedUp,
          riderId: riderId,
          isSynced: true,
          updatedAt: claimTimestamp,
        ));
      }
      return null;
    } catch (e) {
      debugPrint('❌ CRITICAL CLAIM ERROR: $e');
      return 'Sync Error: $e';
    }
  }
}
