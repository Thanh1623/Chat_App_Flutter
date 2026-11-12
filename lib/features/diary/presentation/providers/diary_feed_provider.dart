import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/mappers/diary_post_mapper.dart';
import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryFeedState {
  const DiaryFeedState({
    required this.posts,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<DiaryPost> posts;
  final String? nextCursor;
  final bool loadingMore;

  DiaryFeedState copyWith({
    List<DiaryPost>? posts,
    String? nextCursor,
    bool? loadingMore,
    bool clearCursor = false,
  }) {
    return DiaryFeedState(
      posts: posts ?? this.posts,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

final diaryFeedProvider =
    AsyncNotifierProvider<DiaryFeedNotifier, DiaryFeedState>(
      DiaryFeedNotifier.new,
    );

class DiaryFeedNotifier extends AsyncNotifier<DiaryFeedState> {
  static const _pageSize = 20;

  @override
  Future<DiaryFeedState> build() async {
    final page = await ref
        .read(newsRepositoryProvider)
        .fetchPublishedPosts(limit: _pageSize);
    return DiaryFeedState(
      posts: page.items.map((c) => c.toDiaryPost()).toList(),
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(newsRepositoryProvider)
          .fetchPublishedPosts(limit: _pageSize);
      return DiaryFeedState(
        posts: page.items.map((c) => c.toDiaryPost()).toList(),
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
          .fetchPublishedPosts(limit: _pageSize, cursor: cursor);
      final merged = [
        ...current.posts,
        ...page.items.map((c) => c.toDiaryPost()),
      ];
      state = AsyncData(
        DiaryFeedState(
          posts: merged,
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    DiaryPost? post;
    for (final p in current.posts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }
    if (post == null) return;

    final nextLike = !post.likedByMe;
    try {
      final snapshot = await ref
          .read(newsRepositoryProvider)
          .setLike(postId, like: nextLike);
      final posts = current.posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(
          likeCount: snapshot.total,
          likedByMe: snapshot.likedByMe,
        );
      }).toList();
      state = AsyncData(current.copyWith(posts: posts));
    } catch (_) {}
  }

  Future<void> addComment(String postId, String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final created = await ref
          .read(newsRepositoryProvider)
          .createComment(postId, text);
      final author = created.author;
      final diaryComment = DiaryComment(
        id: created.id,
        author: author != null
            ? DiaryAuthor(
                id: author.id,
                name: author.name,
                avatarUrl: author.avatarUrl,
              )
            : const DiaryAuthor(id: 'me', name: 'Bạn'),
        text: created.body,
      );
      final posts = current.posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(
          commentCount: p.commentCount + 1,
          previewComments: [...p.previewComments, diaryComment],
        );
      }).toList();
      state = AsyncData(current.copyWith(posts: posts));
    } catch (_) {}
  }
}
