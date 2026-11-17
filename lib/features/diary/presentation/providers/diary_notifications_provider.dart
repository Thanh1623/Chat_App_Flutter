import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:chat_app/features/news/domain/entities/news_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryNotificationsState {
  const DiaryNotificationsState({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<NewsNotification> items;
  final String? nextCursor;
  final bool loadingMore;

  DiaryNotificationsState copyWith({
    List<NewsNotification>? items,
    String? nextCursor,
    bool? loadingMore,
    bool clearCursor = false,
  }) {
    return DiaryNotificationsState(
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

final diaryNotificationsProvider =
    AsyncNotifierProvider<DiaryNotificationsNotifier, DiaryNotificationsState>(
      DiaryNotificationsNotifier.new,
    );

class DiaryNotificationsNotifier
    extends AsyncNotifier<DiaryNotificationsState> {
  static const _pageSize = 30;

  @override
  Future<DiaryNotificationsState> build() async {
    final page = await ref
        .read(newsRepositoryProvider)
        .fetchNotifications(limit: _pageSize);
    return DiaryNotificationsState(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(newsRepositoryProvider)
          .fetchNotifications(limit: _pageSize);
      return DiaryNotificationsState(
        items: page.items,
        nextCursor: page.nextCursor,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final cursor = current?.nextCursor;
    if (current == null ||
        cursor == null ||
        cursor.isEmpty ||
        current.loadingMore) {
      return;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(newsRepositoryProvider)
          .fetchNotifications(limit: _pageSize, cursor: cursor);
      state = AsyncData(
        DiaryNotificationsState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}
