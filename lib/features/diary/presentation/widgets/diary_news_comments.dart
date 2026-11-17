import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_composer.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_item.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_comment_tokens.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [feed]: tối đa 2 bình luận gốc mới nhất, không mở rộng inline.
/// [detail]: tải và hiển thị đầy đủ thread như web.
enum DiaryCommentsLayout { feed, detail }

class DiaryNewsComments extends ConsumerStatefulWidget {
  const DiaryNewsComments({
    super.key,
    required this.postId,
    required this.preview,
    required this.myUserId,
    required this.myName,
    this.myAvatarUrl,
    this.canModerate = false,
    this.composerKey,
    this.onFeedRefresh,
    this.layout = DiaryCommentsLayout.feed,
    this.totalCommentCount = 0,
    this.onViewAll,
  });

  final String postId;
  final NewsCommentPage preview;
  final String myUserId;
  final String myName;
  final String? myAvatarUrl;
  final bool canModerate;
  final GlobalKey<DiaryCommentComposerState>? composerKey;
  final VoidCallback? onFeedRefresh;
  final DiaryCommentsLayout layout;
  final int totalCommentCount;
  final VoidCallback? onViewAll;

  @override
  ConsumerState<DiaryNewsComments> createState() => _DiaryNewsCommentsState();
}

class _DiaryNewsCommentsState extends ConsumerState<DiaryNewsComments> {
  static const _feedPreviewMax = 2;

  var _full = false;
  String? _replyToRootId;
  String? _editingId;

  List<NewsComment> _loadedRoots = const [];
  String? _listCursor;
  var _loadingList = false;
  var _loadingMore = false;
  String? _listError;

  bool get _isFeed => widget.layout == DiaryCommentsLayout.feed;
  bool get _isDetail => widget.layout == DiaryCommentsLayout.detail;

  NewsCommentPage get _preview => widget.preview;

  /// Preview feed: BE trả root mới nhất trước, hiển thị cũ → mới (2 dòng).
  List<NewsComment> get _feedRoots {
    final items = _preview.items;
    final take = items.length > _feedPreviewMax
        ? items.take(_feedPreviewMax)
        : items;
    return take.toList().reversed.toList();
  }

  List<NewsComment> get _visibleRoots {
    if (_isFeed) return _feedRoots;
    if (_full && _loadedRoots.isNotEmpty) {
      return _loadedRoots.reversed.toList();
    }
    return _preview.items.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    if (_isDetail) {
      _full = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRootPage(reset: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant DiaryNewsComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview != widget.preview && !_full && _isFeed) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    widget.onFeedRefresh?.call();
    if (_isFeed) {
      ref.invalidate(diaryFeedProvider);
    }
    if (_full) {
      await _loadRootPage(reset: true);
    }
    if (mounted) setState(() {});
  }

  void _viewAll() => widget.onViewAll?.call();

  Future<void> _openFull() async {
    if (_isFeed) {
      _viewAll();
      return;
    }
    setState(() => _full = true);
    if (_loadedRoots.isEmpty) {
      await _loadRootPage(reset: true);
    }
  }

  Future<void> _loadRootPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loadingList = true;
        _listError = null;
        if (reset) {
          _loadedRoots = const [];
          _listCursor = null;
        }
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final repo = ref.read(newsRepositoryProvider);
      final page = await repo.fetchComments(
        widget.postId,
        cursor: reset ? null : _listCursor,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _loadedRoots = page.items;
        } else {
          _loadedRoots = [..._loadedRoots, ...page.items];
        }
        _listCursor = page.nextCursor;
        _listError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _listError = 'Không tải được bình luận.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _loadingMore = false;
        });
      }
    }
  }

  bool get _showViewAllOnFeed {
    if (!_isFeed) return false;
    if (widget.totalCommentCount > _feedPreviewMax) return true;
    if (_preview.nextCursor != null) return true;
    return _feedRoots.any((r) => r.replyCount > 0);
  }

  String get _viewAllLabel {
    final total = widget.totalCommentCount;
    if (total > _feedPreviewMax) {
      return 'Xem tất cả $total bình luận';
    }
  if (_preview.nextCursor != null) {
      return 'Xem thêm bình luận';
    }
    return 'Xem bình luận';
  }

  Widget _linkButton(String label, VoidCallback? onTap, {bool busy = false}) {
    return TextButton(
      onPressed: busy ? null : onTap,
      style: TextButton.styleFrom(
        foregroundColor: DiaryCommentTokens.meta,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        busy ? 'Đang tải…' : label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _commentTile(NewsComment comment, String rootId) {
    final actions = !_isFeed;
    return DiaryCommentItem(
      comment: comment,
      myUserId: widget.myUserId,
      canModerate: widget.canModerate,
      editing: _editingId == comment.id,
      showActions: actions,
      onReply: () async {
        if (_isFeed) {
          _viewAll();
          return;
        }
        await _openFull();
        setState(() => _replyToRootId = rootId);
      },
      onEdit: (on) => setState(() => _editingId = on ? comment.id : null),
      onChanged: _refresh,
      onUpdate: (body) async {
        await ref.read(newsRepositoryProvider).updateComment(comment.id, body);
      },
      onDelete: () async {
        await ref.read(newsRepositoryProvider).deleteComment(comment.id);
        if (!mounted) return;
        await _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isFeed && _showViewAllOnFeed)
            Align(
              alignment: Alignment.centerLeft,
              child: _linkButton(_viewAllLabel, _viewAll),
            ),
          if (_isDetail) ...[
            if (_listCursor != null && _listCursor!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _linkButton(
                  'Xem bình luận trước',
                  () => _loadRootPage(reset: false),
                  busy: _loadingMore,
                ),
              ),
            if (_loadingList && _loadedRoots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (_listError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _listError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    _linkButton('Thử lại', () => _loadRootPage(reset: true)),
                  ],
                ),
              ),
          ],
          for (final root in _visibleRoots) ...[
            _commentTile(root, root.id),
            if (_isFeed && root.replyCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _linkButton(
                    'Xem ${root.replyCount} trả lời',
                    _viewAll,
                  ),
                ),
              ),
            if (!_isFeed &&
                _full &&
                (root.replies.isNotEmpty || _replyToRootId == root.id))
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final reply in root.replies)
                      _commentTile(reply, root.id),
                    if (_replyToRootId == root.id)
                      DiaryCommentComposer(
                        placeholder:
                            'Trả lời ${root.author?.name ?? ''}…',
                        autoFocus: true,
                        onSubmit: (body) => ref
                            .read(newsRepositoryProvider)
                            .createComment(
                              widget.postId,
                              body,
                              parentId: root.id,
                            ),
                        onDone: () {
                          setState(() => _replyToRootId = null);
                          _refresh();
                        },
                        onCancel: () => setState(() => _replyToRootId = null),
                      ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DiaryAvatar(
                name: widget.myName,
                url: widget.myAvatarUrl,
                radius: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DiaryCommentComposer(
                  key: widget.composerKey,
                  placeholder: 'Viết bình luận…',
                  onSubmit: (body) => ref
                      .read(newsRepositoryProvider)
                      .createComment(widget.postId, body),
                  onDone: _refresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}