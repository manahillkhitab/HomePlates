import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dish_provider.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(socialProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : AppTheme.offWhite,
      appBar: AppBar(
        title: Text(
          'Kitchen Stories 📸',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_back_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No stories yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                  // Reload posts
                  final notifier = ref.read(socialProvider.notifier);
                  // We might need a method to force reload in notifier, essentially just re-reading box
                  // Since it's Hive-based, it's already sync, but we can simulate network fetch
                  await Future.delayed(const Duration(seconds: 1));
              },
              color: AppTheme.primaryGold,
              child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppTheme.primaryGold),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chef\'s Kitchen', // Placeholder for chef name lookup
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(post.createdAt),
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Image
                      if (post.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: post.imageUrl.startsWith('http') 
                              ? Image.network(
                                  post.imageUrl,
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                )
                              : Image.file(
                                  File(post.imageUrl),
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                        ),
                      // Actions & Compare
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_border_rounded, size: 28),
                                  onPressed: () => ref.read(socialProvider.notifier).likePost(post.id),
                                ),
                                Text(
                                  '${post.likes} likes',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.caption,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: isDark ? Colors.white70 : AppTheme.warmCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }
}
