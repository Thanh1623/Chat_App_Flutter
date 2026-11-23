import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';
import 'package:chat_app/features/chat/domain/entities/room_media.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:chat_app/features/chat/domain/entities/room_reminder.dart';

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

  /// đây là API để tạo một poll trong phòng chat
  Future<ChatMessage> createPoll({
    required String roomId,
    required String question,
    required List<String> options,
    required bool multiple,
    required bool allowAddOptions,
    DateTime? closesAt,
  });

  /// đây là API để bình chọn cho một poll trong phòng chat
  Future<ChatMessage> votePoll({
    required String roomId,
    required String pollId,
    required List<String> optionIds,
  });

  /// đây là API để thêm một option cho một poll trong phòng chat
  Future<ChatMessage> addPollOption({
    required String roomId,
    required String pollId,
    required String text,
  });

  /// đây là API để đóng một poll trong phòng chat
  Future<ChatMessage> closePoll({
    required String roomId,
    required String pollId,
  });

  Future<List<RoomReminder>> fetchReminders(String roomId);

  Future<RoomReminder> createReminder({
    required String roomId,
    required String title,
    required DateTime remindAt,
    required String repeat,
  });
  Future<RoomReminder> updateReminder({
    required String roomId,
    required String reminderId,
    required String title,
    required DateTime remindAt,
    required String repeat,
  });
  Future<void> deleteReminder({
    required String roomId,
    required String reminderId,
  });
  Stream<String> watchReminders(String roomId);

  /// Tin mới từ Socket. Chỉ room đang mở.
  Stream<ChatMessage> watchMessages(String roomId);
  Stream<List<RoomRead>> watchReads(String roomId);
}
