import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/unread_count_badge.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationListTile extends StatelessWidget {
  const ConversationListTile({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == ConversationType.group;

    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            child: Icon(isGroup ? Icons.groups : Icons.person),
          ),
          if (hasUnread)
            Positioned(
              right: -4,
              top: -4,
              child: UnreadCountBadge(count: conversation.unreadCount),
            ),
        ],
      ),
      title: Text(
        conversation.title,
        style: hasUnread ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      subtitle: Text(
        conversation.lastMessagePreview.isEmpty
            ? 'Chưa có tin nhắn'
            : conversation.lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: hasUnread ? FontWeight.w600 : null,
              color: conversation.lastMessagePreview.isEmpty
                  ? Theme.of(context).colorScheme.outline
                  : null,
            ),
      ),
      onTap: () => context.push(
        AppRoutes.chatPath(conversation.id),
        extra: ChatRouteArgs(
          title: conversation.title,
          canDelete: conversation.canDelete,
          type: conversation.type,
          peerUserId: conversation.peerUserId,
        ),
      ),
    );
  }
}
