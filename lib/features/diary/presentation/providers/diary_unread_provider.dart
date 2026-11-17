import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryUnreadProvider =
    AsyncNotifierProvider<DiaryUnreadNotifier, int>(DiaryUnreadNotifier.new);

class DiaryUnreadNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() =>
      ref.read(newsRepositoryProvider).fetchNotificationUnreadCount();

  void setCount(int count) {
    state = AsyncData(count < 0 ? 0 : count);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(newsRepositoryProvider).fetchNotificationUnreadCount(),
    );
  }

  Future<void> markRead() async {
    try {
      await ref.read(newsRepositoryProvider).markNotificationsRead();
      state = const AsyncData(0);
    } catch (_) {}
  }
}
