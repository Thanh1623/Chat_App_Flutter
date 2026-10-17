import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';

abstract interface class ChatRepository {
  Future<MessagesPage> fetchMessages(
    String roomId, {
    int limit = 80,
    String? cursor,
  });
  Future<ChatMessage> sendMessage(
    String roomId,
    String content, {
    String? replyToId,
  });
  Future<ChatMessage> sendImageMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
    String? caption,
    String? replyToId,
  });
  Future<ChatMessage> sendFileMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
    String? replyToId,
  });

  Future<void> markRead(String roomId, String messageId);

  Future<ChatMessage> pinMessage(
    String roomId,
    String messageId, {
    required bool pinned,
  });
  Future<List<ChatMessage>> fetchPinned(String roomId);
  Future<ChatMessage> reactMessage(
    String roomId,
    String messageId, {
    required String emoji,
  });
  Future<ChatMessage> recallMessage(String roomId, String messageId);
  Future<void> hideMessage(String roomId, String messageId);

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
}
