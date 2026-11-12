import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryUnreadProvider =
    AsyncNotifierProvider<DiaryUnreadNotifier, int>(DiaryUnreadNotifier.new);

class DiaryUnreadNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.read(newsRepositoryProvider).fetchUnreadCount();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(newsRepositoryProvider).fetchUnreadCount(),
    );
  }

  Future<void> markSeen() async {
    try {
      await ref.read(newsRepositoryProvider).markNewsSeen();
      state = const AsyncData(0);
    } catch (_) {}
  }
}
