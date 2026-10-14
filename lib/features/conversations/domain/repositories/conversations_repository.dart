import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';

abstract interface class ConversationsRepository {
  Future<ConversationsPage> fetchConversationsPage({
    int limit = 20,
    String? cursor,
  });

  Future<Conversation> openDirect(String userId);

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  });

  Future<void> deleteRoom(String roomId);
}
