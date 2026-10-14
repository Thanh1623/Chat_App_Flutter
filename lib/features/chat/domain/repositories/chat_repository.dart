import 'package:chat_app/features/chat/domain/entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> fetchMessages(String roomId);
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

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
}
