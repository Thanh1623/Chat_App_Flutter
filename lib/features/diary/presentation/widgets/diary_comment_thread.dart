import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:flutter/material.dart';

class DiaryCommentThread extends StatefulWidget {
  const DiaryCommentThread({
    super.key,
    required this.comments,
    required this.currentUserName,
    this.currentUserAvatarUrl,
    required this.onSubmit,
  });

  final List<DiaryComment> comments;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final ValueChanged<String> onSubmit;

  @override
  State<DiaryCommentThread> createState() => DiaryCommentThreadState();
}

class DiaryCommentThreadState extends State<DiaryCommentThread> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void focusComposer() => _focus.requestFocus();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          for (final comment in widget.comments)
            _CommentRow(comment: comment),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DiaryAvatar(
                name: widget.currentUserName,
                url: widget.currentUserAvatarUrl,
                radius: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Viết bình luận...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: 'Gửi',
                      onPressed: _submit,
                      icon: Icon(
                        Icons.send,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final DiaryComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiaryAvatar(
            name: comment.author.name,
            url: comment.author.avatarUrl,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(fontSize: 14, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
