import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';

abstract interface class ChatRepository {
  Future<MessagesPage> fetchMessages(
    String roomId, {
    int limit = 80,
    String? cursor,
  });
  Future<ChatMessage> sendMessage(String roomId, String content);
  Future<ChatMessage> sendImageMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
    String? caption,
  });
  Future<ChatMessage> sendFileMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
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

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
}
