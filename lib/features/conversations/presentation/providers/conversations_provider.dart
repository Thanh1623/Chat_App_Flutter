import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/conversations/data/datasources/conversations_remote_data_source.dart';
import 'package:chat_app/features/conversations/data/repositories/conversations_repository_impl.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationsRemoteDataSourceProvider =
    Provider<ConversationsRemoteDataSource>((ref) {
  return ConversationsRemoteDataSource(ref.watch(dioProvider));
});

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  return ConversationsRepositoryImpl(ref.watch(conversationsRemoteDataSourceProvider));
});

class ConversationsInboxState {
  const ConversationsInboxState({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<Conversation> items;
  final bool hasMore;
  final String? nextCursor;
  final bool loadingMore;

  ConversationsInboxState copyWith({
    List<Conversation>? items,
    bool? hasMore,
    String? nextCursor,
    bool? loadingMore,
  }) {
    return ConversationsInboxState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class ConversationsInboxNotifier extends AsyncNotifier<ConversationsInboxState> {
  static const _pageSize = 20;

  @override
  Future<ConversationsInboxState> build() async {
    return _fetchFirstPage();
  }

  Future<ConversationsInboxState> _fetchFirstPage() async {
    final page = await ref
        .read(conversationsRepositoryProvider)
        .fetchConversationsPage(limit: _pageSize);
    return ConversationsInboxState(
      items: page.items,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refreshInbox() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  void applyRoomMeta({
    required String id,
    String? title,
    String? avatarUrl,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;
    final nextTitle = title?.trim();
    state = AsyncData(
      current.copyWith(
        items: [
          for (final c in current.items)
            if (c.id != id)
              c
            else
              c.copyWith(
                title: nextTitle != null && nextTitle.isNotEmpty
                    ? nextTitle
                    : c.title,
                avatarUrl: avatarUrl ?? c.avatarUrl,
              ),
        ],
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(conversationsRepositoryProvider).fetchConversationsPage(
            limit: _pageSize,
            cursor: current.nextCursor,
          );
      state = AsyncData(
        ConversationsInboxState(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final conversationsInboxProvider =
    AsyncNotifierProvider<ConversationsInboxNotifier, ConversationsInboxState>(
  ConversationsInboxNotifier.new,
);

/// Danh sách phòng cho UI cũ (tab Danh bạ, badge, socket join).
final conversationsProvider = Provider<AsyncValue<List<Conversation>>>((ref) {
  return ref.watch(conversationsInboxProvider).when(
        data: (state) => AsyncData(state.items),
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
      );
});

final totalUnreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(conversationsProvider);
  return async.maybeWhen(
    data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});
