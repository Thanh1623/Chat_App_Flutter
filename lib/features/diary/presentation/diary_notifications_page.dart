import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_news_sync.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_notifications_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_unread_provider.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:chat_app/features/news/domain/entities/news_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiaryNotificationsPage extends ConsumerStatefulWidget {
  const DiaryNotificationsPage({super.key});

  @override
  ConsumerState<DiaryNotificationsPage> createState() =>
      _DiaryNotificationsPageState();
}

class _DiaryNotificationsPageState
    extends ConsumerState<DiaryNotificationsPage> {
  var _markedRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_markedRead) return;
      _markedRead = true;
      ref.read(diaryUnreadProvider.notifier).markRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(diaryNewsSyncProvider);
    final async = ref.watch(diaryNotificationsProvider);

    return Scaffold(
      backgroundColor: DiaryTokens.feedBg,
      appBar: AppBar(title: const Text('Thông báo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(diaryNotificationsProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(child: Text('Chưa có thông báo'));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(diaryNotificationsProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 240) {
                  ref.read(diaryNotificationsProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFE8E8E8)),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = state.items[index];
                  return _NotificationTile(
                    item: item,
                    onTap: () =>
                        context.push(AppRoutes.diaryPostPath(item.postId)),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NewsNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final preview = item.postExcerpt.trim().isNotEmpty
        ? item.postExcerpt.trim()
        : item.postTitle.trim();

    return Material(
      color: item.unread ? const Color(0xFFE8F0FE) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiaryAvatar(
                name: item.actor.name,
                url: item.actor.avatarUrl,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.actor.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' ${_actionText(item)}'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      formatDiaryTime(item.createdAt.toLocal()),
                      style: TextStyle(color: muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(_typeIcon(item.type), size: 20, color: _typeColor(item.type)),
            ],
          ),
        ),
      ),
    );
  }
}

String _actionText(NewsNotification item) {
  final body = item.commentBody?.trim() ?? '';
  return switch (item.type) {
    NewsNotificationType.like => 'đã thích bài viết của bạn.',
    NewsNotificationType.comment => body.isEmpty
        ? 'đã bình luận về bài viết của bạn.'
        : 'đã bình luận: $body',
    NewsNotificationType.reply => body.isEmpty
        ? 'đã trả lời bình luận của bạn.'
        : 'đã trả lời: $body',
  };
}

IconData _typeIcon(NewsNotificationType type) {
  return switch (type) {
    NewsNotificationType.like => Icons.favorite,
    NewsNotificationType.comment => Icons.chat_bubble,
    NewsNotificationType.reply => Icons.reply,
  };
}

Color _typeColor(NewsNotificationType type) {
  return switch (type) {
    NewsNotificationType.like => DiaryTokens.like,
    NewsNotificationType.comment => DiaryTokens.comment,
    NewsNotificationType.reply => DiaryTokens.comment,
  };
}
