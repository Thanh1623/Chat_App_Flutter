import 'dart:async';

import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_news_sync.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_unread_provider.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_compose_sheet.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_composer.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_post_card.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  final _search = TextEditingController();
  var _markedNewsSeen = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    await openDiaryCompose(context, ref, onError: _soon);
  }

  void _soon([String message = 'Tính năng này sẽ sớm có.']) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<DiaryPost> _visible(List<DiaryPost> posts) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return posts;
    return posts
        .where(
          (post) =>
              post.author.name.toLowerCase().contains(query) ||
              post.caption.toLowerCase().contains(query),
        )
        .toList();
  }

  void _markNewsSeenOnce() {
    if (_markedNewsSeen) return;
    _markedNewsSeen = true;
    Future.microtask(() => ref.read(diaryUnreadProvider.notifier).markSeen());
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(diaryNewsSyncProvider);
    _markNewsSeenOnce();
    final user = ref.watch(authControllerProvider).user;
    final name = user?.displayName ?? 'Bạn';
    final avatar = user?.avatarUrl;
    final feed = ref.watch(diaryFeedProvider);
    final unread = ref.watch(diaryUnreadProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: DiaryTokens.feedBg,
      body: Column(
        children: [
          DiaryTopBar(
            searchController: _search,
            userName: name,
            userAvatarUrl: avatar,
            unreadCount: unread,
            onAvatarTap: () => context.go(AppRoutes.profile),
            onGalleryTap: () => context.push(AppRoutes.gallery),
            onNotificationTap: () {
              ref.read(diaryUnreadProvider.notifier).markSeen();
              ref.read(diaryFeedProvider.notifier).refresh();
            },
          ),
          Expanded(child: _buildBody(context, feed, name, avatar)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<DiaryFeedState> feed,
    String name,
    String? avatar,
  ) {
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(diaryFeedProvider.notifier).refresh(),
      ),
      data: (state) => _buildFeed(context, state, name, avatar),
    );
  }

  Widget _buildFeed(
    BuildContext context,
    DiaryFeedState state,
    String name,
    String? avatar,
  ) {
    final posts = _visible(state.posts);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return RefreshIndicator(
      onRefresh: () => ref.read(diaryFeedProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 240) {
            ref.read(diaryFeedProvider.notifier).loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DiaryComposer(
                userName: name,
                userAvatarUrl: avatar,
                onCompose: () => unawaited(_compose()),
                onPickMedia: () => unawaited(_compose()),
                onMoment: _soon,
                onMemory: _soon,
              ),
            ),
            if (posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Chưa có bài viết')),
              )
            else
              SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return DiaryPostCard(
                    post: post,
                    currentUserName: name,
                    currentUserAvatarUrl: avatar,
                    onOpenDetail: () =>
                        context.push(AppRoutes.diaryPostPath(post.id)),
                    onLike: () => ref
                        .read(diaryFeedProvider.notifier)
                        .toggleLike(post.id),
                    onShare: _soon,
                    onSubmitComment: (text) => ref
                        .read(diaryFeedProvider.notifier)
                        .addComment(post.id, text),
                  );
                },
              ),
            if (state.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (posts.isNotEmpty && state.nextCursor == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'Bạn đã xem hết các bài viết mới',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
