import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/models/review_model.dart';

final reviewProvider = AsyncNotifierProvider<ReviewNotifier, List<ReviewModel>>(
  ReviewNotifier.new,
);

class ReviewNotifier extends AsyncNotifier<List<ReviewModel>> {
  @override
  Future<List<ReviewModel>> build() async {
    // Initial fetch from Supabase
    try {
      final response = await Supabase.instance.client
          .from('reviews')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (data) => ReviewModel(
              id: data['id'],
              customerId: data['customer_id'],
              customerName:
                  data['customer_name'] ?? 'Customer', // Handle potential nulls
              chefId: data['chef_id'],
              dishId: data['dish_id'],
              orderId: data['order_id'],
              rating: data['rating'],
              comment: data['comment'] ?? '',
              createdAt: DateTime.parse(data['created_at']),
            ),
          )
          .toList();
    } catch (e) {
      // Fallback or empty on error
      debugPrint('Review fetch error: $e');
      return [];
    }
  }

  Future<bool> addReview({
    required String customerId,
    required String customerName,
    required String chefId,
    required String dishId,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    try {
      final newReview = {
        'customer_id': customerId,
        'customer_name': customerName,
        'chef_id': chefId,
        'dish_id': dishId,
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
        // created_at is auto info
      };

      final response = await Supabase.instance.client
          .from('reviews')
          .insert(newReview)
          .select()
          .single();

      final reviewModel = ReviewModel(
        id: response['id'],
        customerId: response['customer_id'],
        customerName: response['customer_name'] ?? 'Customer',
        chefId: response['chef_id'],
        dishId: response['dish_id'],
        orderId: response['order_id'],
        rating: response['rating'],
        comment: response['comment'] ?? '',
        createdAt: DateTime.parse(response['created_at']),
      );

      // Update local state
      state = AsyncValue.data([...?state.value, reviewModel]);
      return true;
    } catch (e) {
      debugPrint('Add review error: $e');
      return false;
    }
  }

  // Helper: Check if an order has already been reviewed
  bool hasReviewedOrder(String orderId) {
    // Check current state
    final currentReviews = state.value ?? [];
    return currentReviews.any((review) => review.orderId == orderId);
  }

  // Helper: Get reviews for a specific dish (synchronous filter of state)
  List<ReviewModel> getDishReviews(String dishId) {
    final currentReviews = state.value ?? [];
    return currentReviews.where((review) => review.dishId == dishId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Helper: Calculate average rating for a dish
  double getDishRating(String dishId) {
    final reviews = getDishReviews(dishId);
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  // Helper: Get reviews for a specific chef (synchronous filter of state)
  List<ReviewModel> getChefReviews(String chefId) {
    final currentReviews = state.value ?? [];
    return currentReviews.where((review) => review.chefId == chefId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Helper: Calculate average rating for a chef
  double getChefRating(String chefId) {
    final reviews = getChefReviews(chefId);
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }
}
