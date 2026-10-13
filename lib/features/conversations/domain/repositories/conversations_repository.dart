import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

abstract interface class ConversationsRepository {
  Future<List<Conversation>> fetchConversations();

  Future<Conversation> openDirect(String userId);

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  });

  Future<void> deleteRoom(String roomId);
}
