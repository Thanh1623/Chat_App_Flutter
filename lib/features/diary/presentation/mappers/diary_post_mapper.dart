import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:chat_app/features/news/domain/entities/news_card.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:chat_app/features/news/domain/news_feed_images.dart';

extension NewsCardDiary on NewsCard {
  DiaryPost toDiaryPost() {
    final caption = _caption();
    final author = _diaryAuthor();
    final images = <String>[
      if (cover != null && cover!.displayUrl.isNotEmpty) cover!.displayUrl,
    ];

    return DiaryPost(
      id: id,
      author: author,
      caption: caption,
      createdAt: publishedAt,
      imageUrls: images,
      likeCount: likeCount,
      commentCount: commentCount,
      likedByMe: false,
      previewComments: const [],
    );
  }

  String _caption() {
    final body = excerpt.trim();
    final head = title.trim();
    if (body.isEmpty) return head;
    if (head.isEmpty || head == body || body.startsWith(head)) return body;
    return '$head\n$body';
  }

  DiaryAuthor _diaryAuthor() {
    final fb = source;
    if (fb != null) {
      return DiaryAuthor(id: 'fb', name: fb.name, avatarUrl: '');
    }
    final user = author;
    if (user != null) {
      return DiaryAuthor(
        id: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
      );
    }
    return const DiaryAuthor(id: 'news', name: 'Nhật ký VCB');
  }
}

extension NewsFeedItemDiary on NewsFeedItem {
  DiaryPost toDiaryPost() {
    return DiaryPost(
      id: id,
      author: _diaryAuthor(),
      caption: _caption(),
      createdAt: publishedAt,
      imageUrls: newsFeedImageUrls(
        cover: cover,
        blocks: blocks,
        images: images,
      ),
      likeCount: likeCount,
      commentCount: commentCount,
      likedByMe: likedByMe,
      previewComments: previewComments.map(_toDiaryComment).toList(),
    );
  }

  String _caption() {
    final fromBlocks = blocks
        .where((b) => b.type != NewsBlockType.image)
        .map((b) => b.text?.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .join('\n\n');
    if (fromBlocks.isNotEmpty) {
      return _collapseDiaryCaptionLines(fromBlocks);
    }
    final body = excerpt.trim();
    final head = title.trim();
    if (body.isEmpty) return head;
    if (head.isEmpty || head == body || body.startsWith(head)) {
      return _collapseDiaryCaptionLines(body);
    }
    return _collapseDiaryCaptionLines('$head\n$body');
  }

  DiaryAuthor _diaryAuthor() {
    final fb = source;
    if (fb != null) {
      return DiaryAuthor(id: 'fb', name: fb.name, avatarUrl: '');
    }
    final user = author;
    if (user != null) {
      return DiaryAuthor(
        id: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
      );
    }
    return const DiaryAuthor(id: 'news', name: 'Nhật ký VCB');
  }

  DiaryComment _toDiaryComment(NewsComment comment) =>
      newsCommentToDiary(comment);
}

String _collapseDiaryCaptionLines(String raw) {
  return raw
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join('\n\n');
}

DiaryComment newsCommentToDiary(NewsComment comment) {
  final user = comment.author;
  return DiaryComment(
    id: comment.id,
    author: user != null
        ? DiaryAuthor(id: user.id, name: user.name, avatarUrl: user.avatarUrl)
        : const DiaryAuthor(id: 'user', name: 'Người dùng'),
    text: comment.body,
  );
}
