import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:chat_app/features/diary/presentation/mappers/diary_post_mapper.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_thread.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_compose_sheet.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_image_grid.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_post_engagement.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_post_menu.dart';
import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryPostDetailData {
  const DiaryPostDetailData({
    required this.item,
    required this.post,
    required this.comments,
  });

  final NewsFeedItem item;
  final DiaryPost post;
  final List<DiaryComment> comments;
}

final diaryPostDetailProvider = FutureProvider.autoDispose
    .family<DiaryPostDetailData, String>((ref, postId) async {
      final repo = ref.read(newsRepositoryProvider);
      final item = await repo.fetchPost(postId);
      final page = await repo.fetchComments(postId, limit: 50);
      final post = item.toDiaryPost();
      final comments = page.items.map(newsCommentToDiary).toList();
      return DiaryPostDetailData(item: item, post: post, comments: comments);
    });

class DiaryPostDetailPage extends ConsumerStatefulWidget {
  const DiaryPostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<DiaryPostDetailPage> createState() =>
      _DiaryPostDetailPageState();
}

class _DiaryPostDetailPageState extends ConsumerState<DiaryPostDetailPage> {
  DiaryPost? _postOverride;
  List<DiaryComment>? _commentsOverride;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(diaryPostDetailProvider(widget.postId));
    final user = ref.watch(authControllerProvider).user;
    final name = user?.displayName ?? 'Bạn';
    final avatar = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài viết')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(diaryPostDetailProvider(widget.postId)),
        ),
        data: (data) {
          final post = _postOverride ?? data.post;
          final comments = _commentsOverride ?? data.comments;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    DiaryAvatar(
                      name: post.author.name,
                      url: post.author.avatarUrl,
                      radius: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            formatDiaryTime(post.createdAt),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnDiaryPost(post, user?.id))
                      IconButton(
                        tooltip: 'Thêm',
                        onPressed: () {
                          showDiaryPostMenu(
                            context,
                            onEdit: () async {
                              await openDiaryCompose(
                                context,
                                ref,
                                editPostId: widget.postId,
                              );
                              if (!mounted) return;
                              setState(() {
                                _postOverride = null;
                                _commentsOverride = null;
                              });
                              ref.invalidate(
                                diaryPostDetailProvider(widget.postId),
                              );
                            },
                          );
                        },
                        icon: Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (data.item.title.trim().isNotEmpty &&
                  !_titleRepeats(data.item))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Text(
                    data.item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _BlockText(blocks: data.item.blocks),
              ),
              DiaryImageGrid(urls: post.imageUrls),
              DiaryPostEngagement(
                post: post,
                onLike: () => _toggleLike(post),
                onComment: () {},
              ),
              DiaryCommentThread(
                comments: comments,
                currentUserName: name,
                currentUserAvatarUrl: avatar,
                onSubmit: (text) => _comment(text, post, comments),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _titleRepeats(NewsFeedItem item) {
    final title = item.title.trim();
    if (title.isEmpty) return true;
    for (final block in item.blocks) {
      if (block.type != NewsBlockType.image) {
        final text = block.text?.trim() ?? '';
        if (text == title) return true;
        if (title.endsWith('…') &&
            text.startsWith(title.substring(0, title.length - 1))) {
          return true;
        }
        break;
      }
    }
    return false;
  }

  Future<void> _toggleLike(DiaryPost post) async {
    final next = !post.likedByMe;
    try {
      final snapshot = await ref
          .read(newsRepositoryProvider)
          .setLike(post.id, like: next);
      if (!mounted) return;
      setState(() {
        _postOverride = post.copyWith(
          likedByMe: snapshot.likedByMe,
          likeCount: snapshot.total,
        );
      });
      ref.invalidate(diaryFeedProvider);
    } catch (_) {}
  }

  Future<void> _comment(
    String text,
    DiaryPost post,
    List<DiaryComment> current,
  ) async {
    try {
      final created = await ref
          .read(newsRepositoryProvider)
          .createComment(post.id, text);
      final diaryComment = newsCommentToDiary(created);
      if (!mounted) return;
      setState(() {
        _postOverride = post.copyWith(commentCount: post.commentCount + 1);
        _commentsOverride = [...current, diaryComment];
      });
      ref.invalidate(diaryFeedProvider);
    } catch (_) {}
  }
}

class _BlockText extends StatelessWidget {
  const _BlockText({required this.blocks});

  final List<NewsBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    for (final block in blocks) {
      if (block.type == NewsBlockType.image) continue;
      final text = block.text?.trim() ?? '';
      if (text.isNotEmpty) parts.add(text);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('\n\n'),
      style: const TextStyle(fontSize: 15, height: 1.45),
    );
  }
}
