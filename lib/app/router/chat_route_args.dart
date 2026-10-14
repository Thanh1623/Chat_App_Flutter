import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

class ChatRouteArgs {
  const ChatRouteArgs({
    required this.title,
    this.canDelete = false,
    this.type = ConversationType.direct,
    this.peerUserId,
  });

  final String title;
  final bool canDelete;
  final ConversationType type;
  final String? peerUserId;
}
