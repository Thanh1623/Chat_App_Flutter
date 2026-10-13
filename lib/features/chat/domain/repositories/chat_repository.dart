import 'package:chat_app/features/chat/domain/entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<List<ChatMessage>> fetchMessages(String roomId);
  Future<ChatMessage> sendMessage(String roomId, String content);

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
}
