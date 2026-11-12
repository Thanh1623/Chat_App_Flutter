import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_inbox_sync.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_unread_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Socket đã mở qua [conversationsInboxSyncProvider]; refresh Nhật ký khi có bài mới.
final diaryNewsSyncProvider = Provider<void>((ref) {
  ref.watch(conversationsInboxSyncProvider);

  final sub = ref.read(chatSocketClientProvider).newsPublished.listen((_) {
    ref.invalidate(diaryFeedProvider);
    ref.invalidate(diaryUnreadProvider);
  });

  ref.onDispose(sub.cancel);
});
