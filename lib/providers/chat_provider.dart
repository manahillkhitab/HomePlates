import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/message_model.dart';
import '../utils/constants.dart';

final chatProvider = StateNotifierProvider.family<ChatNotifier, List<MessageModel>, String>(
  (ref, conversationId) => ChatNotifier(conversationId),
);

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final String conversationId;
  
  ChatNotifier(this.conversationId) : super([]) {
    _loadMessages();
  }

  void _loadMessages() {
    final box = Hive.box<MessageModel>(AppConstants.messageBox);
    final messages = box.values
        .where((m) => _belongsToConversation(m))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = messages;
  }

  bool _belongsToConversation(MessageModel message) {
    final parts = conversationId.split('_');
    if (parts.length != 2) return false;
    final user1 = parts[0];
    final user2 = parts[1];
    return (message.senderId == user1 && message.receiverId == user2) ||
           (message.senderId == user2 && message.receiverId == user1);
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final box = Hive.box<MessageModel>(AppConstants.messageBox);
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );

    await box.put(message.id, message);
    _loadMessages();
  }

  Future<void> markAsRead(String messageId) async {
    final box = Hive.box<MessageModel>(AppConstants.messageBox);
    final message = box.get(messageId);
    if (message != null && !message.isRead) {
      await box.put(messageId, message.copyWith(isRead: true));
      _loadMessages();
    }
  }

  int getUnreadCount(String userId) {
    return state.where((m) => m.receiverId == userId && !m.isRead).length;
  }
}

// Helper to generate conversation ID
String getConversationId(String userId1, String userId2) {
  final sorted = [userId1, userId2]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
