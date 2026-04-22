import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/local/models/dish_model.dart';
import '../providers/review_provider.dart';
import '../utils/app_theme.dart';
import '../data/local/models/review_model.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final DishModel? dish;
  final String? chefId;

  const ReviewsScreen({super.key, this.dish, this.chefId});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  
  Future<void> _refreshReviews() async {
    await Future.delayed(const Duration(milliseconds: 800));
    ref.invalidate(reviewProvider);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Get reviews from provider based on what was passed
    final List<ReviewModel> reviews;
    final double rating;
    final String title;

    if (widget.dish != null) {
      reviews = ref.read(reviewProvider.notifier).getDishReviews(widget.dish!.id);
      rating = ref.read(reviewProvider.notifier).getDishRating(widget.dish!.id);
      title = 'Dish Reviews';
    } else if (widget.chefId != null) {
      reviews = ref.read(reviewProvider.notifier).getChefReviews(widget.chefId!);
      rating = ref.read(reviewProvider.notifier).getChefRating(widget.chefId!);
      title = 'Kitchen Reviews';
    } else {
      reviews = [];
      rating = 0.0;
      title = 'Reviews';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshReviews,
        color: AppTheme.mutedSaffron,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                title: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.mutedSaffron,
                  ),
                ),
                centerTitle: false,
              ),
            ),
                
                if (reviews.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border_rounded, 
                            size: 100, 
                            color: AppTheme.mutedSaffron.withValues(alpha: 0.3)
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No reviews yet',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this dish!',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Average Rating Header
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                   return Icon(
                                     index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                     color: AppTheme.mutedSaffron,
                                     size: 20,
                                   );
                                }),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Based on ${reviews.length} reviews',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.mutedSaffron.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, color: AppTheme.mutedSaffron, size: 40),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Reviews List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final review = reviews[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review.customerName.isNotEmpty ? review.customerName : 'Verified Customer',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(review.createdAt),
                                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: AppTheme.mutedSaffron,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  review.comment,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8), 
                                    height: 1.5,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: reviews.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          ),
        );
  }
}


