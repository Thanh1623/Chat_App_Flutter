import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/unread_count_badge.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

String _inboxTime(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return hm;
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

class ConversationListTile extends StatelessWidget {
  const ConversationListTile({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.type == ConversationType.group;
    final avatarUrl = conversation.avatarUrl.trim();
    final hasUnread = conversation.unreadCount > 0;

    Widget leadingAvatar;
    if (isGroup && avatarUrl.isEmpty) {
      leadingAvatar = CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.groups,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    } else {
      leadingAvatar = ChatMessageAvatar(
        displayName: conversation.title,
        avatarUrl: avatarUrl,
        radius: 22,
      );
    }

    return ListTile(
      leading: leadingAvatar,
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _inboxTime(conversation.updatedAt),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            UnreadCountBadge(count: conversation.unreadCount),
          ],
        ],
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
