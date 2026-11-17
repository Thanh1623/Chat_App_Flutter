import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_composer.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_tokens.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:flutter/material.dart';

class DiaryCommentItem extends StatelessWidget {
  const DiaryCommentItem({
    super.key,
    required this.comment,
    required this.myUserId,
    required this.canModerate,
    required this.editing,
    required this.onReply,
    required this.onEdit,
    required this.onChanged,
    required this.onUpdate,
    required this.onDelete,
    this.showActions = true,
  });

  final NewsComment comment;
  final String myUserId;
  final bool canModerate;
  final bool editing;
  final VoidCallback onReply;
  final void Function(bool editing) onEdit;
  final VoidCallback onChanged;
  final Future<void> Function(String body) onUpdate;
  final Future<void> Function() onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    final name = author?.name.trim().isNotEmpty == true
        ? author!.name
        : 'Người dùng cũ';
    final mine =
        author != null && author.id.isNotEmpty && author.id == myUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiaryAvatar(
            name: name,
            url: author?.avatarUrl,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (editing)
                  DiaryCommentComposer(
                    placeholder: 'Sửa bình luận…',
                    initial: comment.body,
                    submitText: 'Lưu',
                    autoFocus: true,
                    onSubmit: onUpdate,
                    onDone: () {
                      onEdit(false);
                      onChanged();
                    },
                    onCancel: () => onEdit(false),
                  )
                else ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    decoration: BoxDecoration(
                      color: DiaryCommentTokens.bubble,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comment.body,
                          style: const TextStyle(fontSize: 14, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  if (showActions)
                    _CommentMeta(
                      comment: comment,
                      mine: mine,
                      canModerate: canModerate,
                      editing: editing,
                      onReply: onReply,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentMeta extends StatelessWidget {
  const _CommentMeta({
    required this.comment,
    required this.mine,
    required this.canModerate,
    required this.editing,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  final NewsComment comment;
  final bool mine;
  final bool canModerate;
  final bool editing;
  final VoidCallback onReply;
  final void Function(bool editing) onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final at = comment.createdAt;
    final timeLabel =
        at != null ? formatNewsCommentTime(at) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 0, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          if (timeLabel.isNotEmpty)
            Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: DiaryCommentTokens.meta,
              ),
            ),
          _LinkButton(label: 'Trả lời', onTap: onReply),
          if (mine && !editing)
            _LinkButton(label: 'Sửa', onTap: () => onEdit(true)),
          if (mine || canModerate)
            _LinkButton(
              label: 'Xóa',
              onTap: () => _confirmDelete(context),
            ),
          if (comment.editedAt != null)
            const Text(
              'Đã sửa',
              style: TextStyle(fontSize: 12, color: DiaryCommentTokens.meta),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final replies = comment.replyCount;
    final message = replies > 0
        ? 'Xóa bình luận này và $replies trả lời?'
        : 'Xóa bình luận này?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await onDelete();
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DiaryCommentTokens.meta,
        ),
      ),
    );
  }
}