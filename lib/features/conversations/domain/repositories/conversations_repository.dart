import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

abstract interface class ConversationsRepository {
  Future<List<Conversation>> fetchConversations();
}
