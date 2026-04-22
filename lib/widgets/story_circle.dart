import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/models/post_model.dart';
import '../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryCircle extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const StoryCircle({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine if seen? For now, assume unseen (colorful border).
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3), // Border width
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.purple], // Instagram-like gradient
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2), // Gap between border and image
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: _buildChefImage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                post.chefName ?? 'Chef',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChefImage() {
    final image = post.chefProfileImage;
    if (image == null || image.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey);
    }

    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppTheme.offWhite),
        errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
      );
    } else {
      return Image.file(
        File(image),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
      );
    }
  }
}
