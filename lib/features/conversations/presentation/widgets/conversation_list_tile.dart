import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationListTile extends StatelessWidget {
  const ConversationListTile({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == ConversationType.group;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(isGroup ? Icons.groups : Icons.person),
      ),
      title: Text(conversation.title),
      subtitle: Text(
        conversation.lastMessagePreview.isEmpty
            ? 'Chưa có tin nhắn'
            : conversation.lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: conversation.lastMessagePreview.isEmpty
                  ? Theme.of(context).colorScheme.outline
                  : null,
            ),
      ),
      trailing: conversation.unreadCount > 0
          ? Badge(label: Text('${conversation.unreadCount}'))
          : null,
      onTap: () => context.push(
        AppRoutes.chatPath(conversation.id),
        extra: ChatRouteArgs(
          title: conversation.title,
          canDelete: conversation.canDelete,
        ),
      ),
    );
  }
}
