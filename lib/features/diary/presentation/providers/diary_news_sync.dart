import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_inbox_sync.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_notifications_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_unread_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Socket đã mở qua [conversationsInboxSyncProvider]; refresh Nhật ký khi có bài mới.
final diaryNewsSyncProvider = Provider<void>((ref) {
  ref.watch(conversationsInboxSyncProvider);
  final socket = ref.read(chatSocketClientProvider);

  final published = socket.newsPublished.listen((_) {
    ref.invalidate(diaryFeedProvider);
  });
  final notifications = socket.newsNotifications.listen((data) {
    final count = (data['unread'] as num?)?.toInt();
    if (count != null) {
      ref.read(diaryUnreadProvider.notifier).setCount(count);
    } else {
      ref.invalidate(diaryUnreadProvider);
    }
    ref.invalidate(diaryNotificationsProvider);
  });

  ref.onDispose(() {
    published.cancel();
    notifications.cancel();
  });
});
