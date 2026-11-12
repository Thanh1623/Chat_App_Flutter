import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:flutter/material.dart';

class DiaryPostEngagement extends StatelessWidget {
  const DiaryPostEngagement({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  final DiaryPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

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
                      child: Text(
                        _likeLabel(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (post.commentCount > 0)
                    Text(
                      '${post.commentCount} bình luận',
                      style: TextStyle(color: muted, fontSize: 13),
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

String _likeLabel(DiaryPost post) {
  if (post.likedByMe && post.likeCount == 1) return 'Bạn';
  if (post.likedByMe) {
    final others = post.likeCount - 1;
    if (post.topLikerName != null && others == 1) {
      return 'Bạn và ${post.topLikerName}';
    }
    return 'Bạn và $others người khác';
  }
  final name = post.topLikerName;
  if (name == null || name.isEmpty) return '${post.likeCount}';
  if (post.likeCount == 1) return name;
  return '$name và ${post.likeCount - 1} người khác';
}

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
