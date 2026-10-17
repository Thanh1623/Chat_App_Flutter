import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';
import 'package:chat_app/features/chat/domain/entities/room_media.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';

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

  Future<List<RoomRead>> markRead(String roomId, String messageId);
  Future<List<RoomRead>> fetchReads(String roomId);

  Future<ChatMessage> pinMessage(
    String roomId,
    String messageId, {
    required bool pinned,
  });
  Future<List<ChatMessage>> fetchPinned(String roomId);
  Future<List<RoomMediaImage>> fetchRoomImages(String roomId);
  Future<List<RoomMediaFile>> fetchRoomFiles(String roomId);
  Future<List<RoomMediaLink>> fetchRoomLinks(String roomId);
  Future<ChatMessage> reactMessage(
    String roomId,
    String messageId, {
    required String emoji,
  });
  Future<ChatMessage> recallMessage(String roomId, String messageId);
  Future<void> hideMessage(String roomId, String messageId);

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
  Stream<List<RoomRead>> watchReads(String roomId);
}
