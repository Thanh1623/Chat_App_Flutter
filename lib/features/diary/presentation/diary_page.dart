import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final name = user?.displayName ?? 'Bạn';
    final avatar = user?.avatarUrl;
    final posts = _visible(ref.watch(diaryFeedProvider).posts);

    return Scaffold(
      backgroundColor: DiaryTokens.feedBg,
      body: Column(
        children: [
          DiaryTopBar(
            searchController: _search,
            userName: name,
            userAvatarUrl: avatar,
            onAvatarTap: () => context.go(AppRoutes.profile),
            onGalleryTap: () => context.push(AppRoutes.gallery),
            onNotificationTap: _soon,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: DiaryComposer(
                      userName: name,
                      userAvatarUrl: avatar,
                      onCompose: _soon,
                      onPickMedia: _soon,
                      onMoment: _soon,
                      onMemory: _soon,
                    ),
                  ),
                  if (posts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Không tìm thấy bài viết')),
                    )
                  else
                    SliverList.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return DiaryPostCard(
                          post: post,
                          currentUserName: name,
                          currentUserAvatarUrl: avatar,
                          onLike: () => ref
                              .read(diaryFeedProvider.notifier)
                              .toggleLike(post.id),
                          onShare: _soon,
                          onSubmitComment: (_) => _soon(),
                        );
                      },
                    ),
                  if (posts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Bạn đã xem hết các bài viết mới',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
