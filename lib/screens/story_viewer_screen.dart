import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/post_model.dart';
import '../providers/social_provider.dart';
import '../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const StoryViewerScreen({super.key, required this.post});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    if (_isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
      ref.read(socialProvider.notifier).likePost(widget.post.id);
    } else {
      ref.read(socialProvider.notifier).unlikePost(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(socialProvider);
    final currentPost = posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image / Background
          GestureDetector(
            onDoubleTap: _handleLike,
            onTap: () => Navigator.pop(context),
            child: Center(child: _buildMainImage()),
          ),

          // Header Overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryGold.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage:
                        widget.post.chefProfileImage != null &&
                            widget.post.chefProfileImage!.isNotEmpty
                        ? CachedNetworkImageProvider(
                                widget.post.chefProfileImage!,
                              )
                              as ImageProvider
                        : null,
                    child:
                        (widget.post.chefProfileImage == null ||
                            widget.post.chefProfileImage!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 18,
                            color: AppTheme.primaryGold,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.chefName ?? 'Chef',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timeago.format(widget.post.createdAt),
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content & Interaction Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                40,
                16,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 4),
                      child: Text(
                        widget.post.caption,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      // Like & Count
                      Column(
                        children: [
                          ScaleTransition(
                            scale: _likeAnimation,
                            child: IconButton(
                              icon: Icon(
                                _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: _isLiked
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 28,
                              ),
                              onPressed: _handleLike,
                            ),
                          ),
                          Text(
                            '${currentPost.likes}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Message Input
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _commentController,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                            cursorColor: AppTheme.primaryGold,
                            decoration: InputDecoration(
                              hintText: 'Send message...',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (val) => _sendMessage(val),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Send Icon
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _sendMessage(_commentController.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String val) async {
    if (val.trim().isNotEmpty) {
      final currentUser = ref.read(authProvider).value;
      if (currentUser != null) {
        final conversationId = getConversationId(
          currentUser.id,
          widget.post.chefId,
        );
        await ref
            .read(chatProvider(conversationId).notifier)
            .sendMessage(
              senderId: currentUser.id,
              receiverId: widget.post.chefId,
              text: val.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message sent!')));
        }
      }
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildMainImage() {
    final url = widget.post.imageUrl;
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_edu_rounded,
              color: AppTheme.primaryGold,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Kitchen Story from ${widget.post.chefName ?? "Chef"}',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
