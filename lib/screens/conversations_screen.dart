import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/message_model.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<MessageModel>(AppConstants.messageBox).listenable(),
        builder: (context, Box<MessageModel> box, _) {
          final messages = box.values.toList();
          
          // Group messages by conversation
          final conversations = <String, MessageModel>{};
          for (var msg in messages) {
            if (msg.senderId == currentUser.id || msg.receiverId == currentUser.id) {
              final otherId = msg.senderId == currentUser.id ? msg.receiverId : msg.senderId;
              final existing = conversations[otherId];
              if (existing == null || msg.createdAt.isAfter(existing.createdAt)) {
                conversations[otherId] = msg;
              }
            }
          }

          final sortedOtherUserIds = conversations.keys.toList()
            ..sort((a, b) => conversations[b]!.createdAt.compareTo(conversations[a]!.createdAt));

          if (sortedOtherUserIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppTheme.primaryGold.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  Text(
                    'No messages yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedOtherUserIds.length,
            itemBuilder: (context, index) {
              final otherId = sortedOtherUserIds[index];
              final lastMsg = conversations[otherId]!;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primaryGold),
                  ),
                  title: Text(
                    otherId.length > 8
                        ? 'User ID: ${otherId.substring(0, 8)}...'
                        : 'User ID: $otherId', // Ideally fetch name
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMsg.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(lastMsg.createdAt),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if (!lastMsg.isRead && lastMsg.receiverId == currentUser.id)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: otherId,
                          otherUserName: 'Chat', // Ideally fetch name
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
