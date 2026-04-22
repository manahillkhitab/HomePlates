import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/user_model.dart';
import '../data/local/models/dish_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dish_provider.dart';
import '../providers/social_provider.dart';
import '../utils/app_theme.dart';
import 'reviews_screen.dart';
import 'wallet_screen.dart'; // Added this import
import '../widgets/dish_card.dart';
import '../providers/review_provider.dart';
import 'chat_screen.dart';

class ChefProfileScreen extends ConsumerStatefulWidget {
  final String chefId;
  const ChefProfileScreen({super.key, required this.chefId});

  @override
  ConsumerState<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends ConsumerState<ChefProfileScreen> {
  int _followerCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final count = await ref.read(authProvider.notifier).getFollowerCount(widget.chefId);
    if (mounted) {
      setState(() {
        _followerCount = count;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final currentUser = ref.watch(authProvider).value;
    final chefAsync = ref.watch(userByIdProvider(widget.chefId));
    
    final chefDishes = ref.watch(dishProvider).value?.where((d) => d.chefId == widget.chefId).toList() ?? [];
    final chefRating = ref.read(reviewProvider.notifier).getChefRating(widget.chefId);
    final chefReviews = ref.read(reviewProvider.notifier).getChefReviews(widget.chefId);
    final chefStories = ref.watch(socialProvider).where((s) => s.chefId == widget.chefId).toList();
    
    return chefAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (chef) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChefHeader(context, currentUser, chef, ref, chefRating, chefReviews.length),
                    const SizedBox(height: 32),
                    
                    if (chefStories.isNotEmpty) ...[
                      Text(
                        'KITCHEN STORIES',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chefStories.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final story = chefStories[index];
                            return Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: story.imageUrl.startsWith('http')
                                  ? Image.network(
                                      story.imageUrl, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildStoryFallback(),
                                    )
                                  : Image.file(
                                      File(story.imageUrl), 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildStoryFallback(),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    Text(
                      'KITCHEN MENU',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final isMe = currentUser?.id == widget.chefId;
                    return DishCard(
                      dish: chefDishes[index],
                      showStats: isMe, // Stats mode for Chef (hides ETA, shows Count)
                    );
                  },
                  childCount: chefDishes.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.warmCharcoal,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
             Container(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
             Center(
               child: Icon(Icons.restaurant_menu_rounded, size: 80, color: AppTheme.primaryGold.withValues(alpha: 0.2)),
             ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildChefHeader(BuildContext context, UserModel? currentUser, UserModel? chef, WidgetRef ref, double rating, int reviewCount) {
    if (chef == null) return const SizedBox();
    
    final bool isMe = currentUser?.id == widget.chefId;
    final bool isFollowing = currentUser?.followingChefIds.contains(widget.chefId) ?? false;
    final bool isTopMerchant = rating >= 4.5;
    final String displayName = chef.kitchenName.isNotEmpty ? chef.kitchenName : chef.name;

    return Row(
      children: [
        // Profile Image with Fallback
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.warmCharcoal,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: ClipOval(
            child: chef.profileImageUrl.isNotEmpty
                ? (chef.profileImageUrl.startsWith('http')
                    ? Image.network(
                        chef.profileImageUrl, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildProfileFallback(),
                      )
                    : Image.file(
                        File(chef.profileImageUrl), 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildProfileFallback(),
                      ))
                : _buildProfileFallback(),
          ),
        ),
        const SizedBox(width: 20),
        
        // Name and Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.isNotEmpty ? displayName : 'Unnamed Kitchen',
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              
              // Ratings Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($reviewCount Reviews)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              if (isTopMerchant) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Kitchen',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Action Buttons or Stats
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isMe) ...[
              // MY PROFILE VIEW: Show Stats
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _isLoadingStats ? '-' : '$_followerCount',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, 
                        fontSize: 18, 
                        color: AppTheme.primaryGold
                      ),
                    ),
                    Text(
                      'Followers',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Optional: Add Story Views if we had the data
            ] else ...[
              // CUSTOMER VIEW: Show Follow Button + Count
              ElevatedButton(
                onPressed: () async {
                  if (currentUser == null) return;
                  
                  final updatedFollowing = List<String>.from(currentUser.followingChefIds);
                  if (isFollowing) {
                    updatedFollowing.remove(widget.chefId);
                    setState(() => _followerCount--); // Optimistic Update
                  } else {
                    updatedFollowing.add(widget.chefId);
                    setState(() => _followerCount++); // Optimistic Update
                  }
                  
                  await ref.read(authProvider.notifier).updateProfile(
                    currentUser.copyWith(followingChefIds: updatedFollowing),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey[200] : AppTheme.primaryGold,
                  foregroundColor: isFollowing ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  isFollowing ? 'FOLLOWING' : 'FOLLOW',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
              const SizedBox(height: 6),
              if (!_isLoadingStats)
                Text(
                  '$_followerCount Followers',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: chef.id,
                          otherUserName: displayName.isNotEmpty ? displayName : 'Chef',
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGold, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 30),
                ),
                child: Text(
                  'MESSAGE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900, 
                    fontSize: 10,
                    color: AppTheme.primaryGold
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProfileFallback() {
    return Container(
      color: AppTheme.primaryGold.withValues(alpha: 0.1),
      child: const Icon(Icons.restaurant_rounded, color: AppTheme.primaryGold, size: 30),
    );
  }
  
  Widget _buildStoryFallback() {
    return Container(
      color: AppTheme.primaryGold.withValues(alpha: 0.1),
      child: const Icon(Icons.history_edu_rounded, color: AppTheme.primaryGold, size: 24),
    );
  }
}
