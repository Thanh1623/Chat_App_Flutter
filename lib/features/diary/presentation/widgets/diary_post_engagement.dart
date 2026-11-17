import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/utils/diary_like_label.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_reaction_users_sheet.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:chat_app/features/news/data/providers/news_reaction_users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widget hiển thị số lượng like và bình luận
class DiaryPostEngagement extends ConsumerWidget {
  const DiaryPostEngagement({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onViewComments,
  });

  final DiaryPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onViewComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final myId = ref.watch(authControllerProvider).user?.id;
    // Xem danh sách người đã thích
    final usersAsync = post.likeCount > 0
        ? ref.watch(newsPostReactionUsersProvider(post.id))
        : null;
    // Tạo label cho số lượng like và người like đầu tiên
    final summaryLabel = usersAsync == null
        ? diaryLikeSummaryLabel(
            likeCount: post.likeCount,
            likedByMe: post.likedByMe,
          )
        : usersAsync.when(
            data: (items) => diaryLikeSummaryLabel(
              likeCount: post.likeCount,
              likedByMe: post.likedByMe,
              topName: primaryLikerName(items, myUserId: myId),
            ),
            loading: () => diaryLikeSummaryLabel(
              likeCount: post.likeCount,
              likedByMe: post.likedByMe,
            ),
            error: (_, _) => diaryLikeSummaryLabel(
              likeCount: post.likeCount,
              likedByMe: post.likedByMe,
            ),
          );

    // Mở sheet để xem danh sách người đã thích
    Future<void> openLikers() async {
      if (post.likeCount <= 0) return;
      final items = await ref.read(
        newsPostReactionUsersProvider(post.id).future,
      );
      if (!context.mounted) return;
      await showDiaryReactionUsersSheet(
        context: context,
        items: items,
        myUserId: myId,
      );
    }

    // Xây dựng widget hiển thị số lượng like và bình luận
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          if (post.likeCount > 0 || post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  if (post.likeCount > 0) ...[
                    const _ReactionDot(
                      icon: Icons.favorite,
                      color: DiaryTokens.like,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: openLikers,
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          summaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (post.commentCount > 0)
                    InkWell(
                      onTap: onViewComments ?? onComment,
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        '${post.commentCount} bình luận',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          Divider(height: 1, color: Colors.grey.shade300),
          Row(
            children: [
              _Action(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                label: 'Thích',
                color: post.likedByMe ? DiaryTokens.like : muted,
                onTap: onLike,
              ),
              _Action(
                icon: Icons.chat_bubble_outline,
                label: 'Bình luận',
                color: muted,
                onTap: onComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị dot cho loại like
class _ReactionDot extends StatelessWidget {
  const _ReactionDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}

// Widget hiển thị action cho like và bình luận
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
