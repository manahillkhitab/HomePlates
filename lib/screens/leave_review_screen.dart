import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_provider.dart';
import '../data/local/models/order_model.dart';
import '../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String customerName;

  const LeaveReviewScreen({
    super.key,
    required this.order,
    required this.customerName,
  });

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please share your thoughts!')),
      );
      return;
    }

    final success = await ref
        .read(reviewProvider.notifier)
        .addReview(
          customerId: widget.order.customerId,
          customerName: widget.customerName,
          chefId: widget.order.chefId,
          dishId: widget.order.dishId,
          orderId: widget.order.id,
          rating: _rating,
          comment: _commentController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                'Rate Experience',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.mutedSaffron,
                ),
              ),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Dish Image & Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.mutedSaffron.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: widget.order.dishImagePath.isNotEmpty
                                ? (widget.order.dishImagePath.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: widget.order.dishImagePath,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                        )
                                      : Image.file(
                                          File(widget.order.dishImagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                        ))
                                : const Icon(
                                    Icons.restaurant,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.order.dishName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (widget.order.chefName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'by ${widget.order.chefName}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'How was your meal?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Star Rating - FIXED OVERFLOW
                        FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Icon(
                                    index < _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppTheme.mutedSaffron,
                                    size: 44, // Slightly controlled size
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Comment Label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'YOUR FEEDBACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Comment Field
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with the chef...',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: AppTheme.mutedSaffron.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppTheme.mutedSaffron,
                          width: 2,
                        ),
                      ),
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mutedSaffron,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'SUBMIT REVIEW',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
