import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_thread.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_image_grid.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_post_engagement.dart';
import 'package:flutter/material.dart';

class DiaryPostCard extends StatefulWidget {
  const DiaryPostCard({
    super.key,
    required this.post,
    required this.currentUserName,
    this.currentUserAvatarUrl,
    required this.onLike,
    required this.onShare,
    required this.onSubmitComment,
    this.onOpenDetail,
  });

  final DiaryPost post;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final ValueChanged<String> onSubmitComment;
  final VoidCallback? onOpenDetail;

  @override
  State<DiaryPostCard> createState() => _DiaryPostCardState();
}

class _DiaryPostCardState extends State<DiaryPostCard> {
  final _commentKey = GlobalKey<DiaryCommentThreadState>();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final child = ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
            child: Row(
              children: [
                DiaryAvatar(
                  name: widget.post.author.name,
                  url: widget.post.author.avatarUrl,
                  radius: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDiaryTime(widget.post.createdAt),
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Thêm',
                  onPressed: widget.onShare,
                  icon: Icon(Icons.more_horiz, color: muted),
                ),
              ],
            ),
          ),
          if (widget.post.caption.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                widget.post.imageUrls.isEmpty ? 10 : 4,
              ),
              child: Text(
                widget.post.caption.trim(),
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
          DiaryImageGrid(urls: widget.post.imageUrls),
          DiaryPostEngagement(
            post: widget.post,
            onLike: widget.onLike,
            onComment: () => _commentKey.currentState?.focusComposer(),
            onShare: widget.onShare,
          ),
          DiaryCommentThread(
            key: _commentKey,
            comments: widget.post.previewComments,
            currentUserName: widget.currentUserName,
            currentUserAvatarUrl: widget.currentUserAvatarUrl,
            onSubmit: widget.onSubmitComment,
          ),
        ],
      ),
    );

    if (widget.onOpenDetail == null) return child;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: widget.onOpenDetail,
        child: child,
      ),
    );
  }
}
