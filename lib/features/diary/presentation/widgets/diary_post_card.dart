import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_composer.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_image_grid.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_news_comments.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_post_engagement.dart';
import 'package:flutter/material.dart';

class DiaryPostCard extends StatefulWidget {
  const DiaryPostCard({
    super.key,
    required this.post,
    required this.myUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl,
    required this.onLike,
    this.onMore,
    this.onOpenDetail,
  });

  final DiaryPost post;
  final String myUserId;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final VoidCallback onLike;
  final VoidCallback? onMore;
  final VoidCallback? onOpenDetail;

  @override
  State<DiaryPostCard> createState() => _DiaryPostCardState();
}

class _DiaryPostCardState extends State<DiaryPostCard> {
  final _composerKey = GlobalKey<DiaryCommentComposerState>();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final header = Padding(
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
          if (widget.onMore != null)
            IconButton(
              tooltip: 'Thêm',
              onPressed: widget.onMore,
              icon: Icon(Icons.more_horiz, color: muted),
            ),
        ],
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
        DiaryImageGrid(urls: widget.post.imageUrls),
      ],
    );

    final tappable = widget.onOpenDetail == null
        ? Column(children: [header, body])
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpenDetail,
              child: Column(children: [header, body]),
            ),
          );

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tappable,
          DiaryPostEngagement(
            post: widget.post,
            onLike: widget.onLike,
            onComment: () => _composerKey.currentState?.focusComposer(),
            onViewComments: widget.onOpenDetail,
          ),
          DiaryNewsComments(
            postId: widget.post.id,
            preview: widget.post.commentPreview,
            myUserId: widget.myUserId,
            myName: widget.currentUserName,
            myAvatarUrl: widget.currentUserAvatarUrl,
            composerKey: _composerKey,
            layout: DiaryCommentsLayout.feed,
            totalCommentCount: widget.post.commentCount,
            onViewAll: widget.onOpenDetail,
          ),
        ],
      ),
    );
  }
}