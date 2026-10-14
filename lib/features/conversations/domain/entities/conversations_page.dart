import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

class ConversationsPage {
  const ConversationsPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Conversation> items;
  final bool hasMore;
  final String? nextCursor;
}
