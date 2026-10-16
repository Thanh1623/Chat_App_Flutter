import 'package:chat_app/features/chat/domain/entities/chat_message.dart';

class MessagesPage {
  const MessagesPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ChatMessage> items;
  final bool hasMore;
  final String? nextCursor;
}
