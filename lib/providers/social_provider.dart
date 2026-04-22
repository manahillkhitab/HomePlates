import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/post_model.dart';
import '../utils/constants.dart';

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

final socialProvider = StateNotifierProvider<SocialNotifier, List<PostModel>>((ref) {
  return SocialNotifier();
});

class SocialNotifier extends StateNotifier<List<PostModel>> {
  SocialNotifier() : super([]) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      
      final response = await Supabase.instance.client
          .from('stories')
          .select('*, profiles:chef_id(name, kitchen_name, profile_image_url)') // Join with users table
          .gt('created_at', yesterday.toIso8601String())
          .order('created_at', ascending: false);

      final posts = (response as List).map((data) {
         final profile = data['profiles'] as Map<String, dynamic>?;
         final chefName = profile?['kitchen_name'] as String? ?? profile?['name'] as String?;
         return PostModel(
            id: data['id'],
            chefId: data['chef_id'],
            imageUrl: data['media_url'],
            caption: data['caption'] ?? '',
            createdAt: DateTime.parse(data['created_at']),
            likes: 0,
             chefName: chefName,
             chefProfileImage: profile?['profile_image_url'] as String?,
           );
      }).toList();

      state = posts;
    } catch (e) {
      // Fallback
      debugPrint('Error loading stories with profiles: $e');
      // Try loading without profiles as backup
       try {
          final response = await Supabase.instance.client
            .from('active_stories')
            .select()
            .order('created_at', ascending: false);
          
           final posts = (response as List).map((data) => PostModel(
              id: data['id'],
              chefId: data['chef_id'],
              imageUrl: data['media_url'],
              caption: data['caption'] ?? '',
              createdAt: DateTime.parse(data['created_at']),
              likes: 0,
            )).toList();
            state = posts;
       } catch (e2) {
          debugPrint('Error fallback loading stories: $e2');
       }
    }
  }

  Future<void> createPost({
    required String chefId,
    required String imagePath,
    required String caption,
  }) async {
    try {
      String finalImageUrl = imagePath;

      // Upload Image
      if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
        final file = File(imagePath);
        final fileExt = path.extension(imagePath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';

        await Supabase.instance.client.storage
            .from('story_images')
            .upload(fileName, file);

        finalImageUrl = Supabase.instance.client.storage
            .from('story_images')
            .getPublicUrl(fileName);
      }

      // Insert into DB
      await Supabase.instance.client.from('stories').insert({
        'chef_id': chefId,
        'media_url': finalImageUrl,
        'media_type': 'image',
        'caption': caption,
      });

      // Reload
      await loadPosts();
    } catch (e) {
      debugPrint('Error creating story: $e');
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    // Optimistic update locally for now
    state = [
      for (final post in state)
        if (post.id == postId) post.copyWith(likes: post.likes + 1) else post
    ];
  }

  Future<void> unlikePost(String postId) async {
    state = [
      for (final post in state)
        if (post.id == postId) post.copyWith(likes: (post.likes > 0 ? post.likes - 1 : 0)) else post
    ];
  }

  List<PostModel> getPostsForChef(String chefId) {
    return state.where((p) => p.chefId == chefId).toList();
  }
}
