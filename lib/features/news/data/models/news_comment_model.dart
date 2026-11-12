import 'package:chat_app/features/news/data/models/news_models.dart';
import 'package:chat_app/features/news/domain/entities/news_card.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';

class NewsCommentModel {
  NewsCommentModel.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      postId = json['postId']?.toString() ?? '',
      parentId = json['parentId']?.toString(),
      body = json['body']?.toString() ?? '',
      author = NewsCardModel.parseAuthor(json['author']),
      createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      replyCount = (json['replyCount'] as num?)?.toInt() ?? 0,
      replies = (json['replies'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NewsCommentModel.fromJson)
          .map((m) => m.toEntity())
          .toList();

  final String id;
  final String postId;
  final String? parentId;
  final String body;
  final NewsAuthor? author;
  final DateTime? createdAt;
  final int replyCount;
  final List<NewsComment> replies;

  NewsComment toEntity() => NewsComment(
    id: id,
    postId: postId,
    parentId: parentId,
    body: body,
    author: author,
    createdAt: createdAt,
    replyCount: replyCount,
    replies: replies,
  );
}

class NewsCommentPageModel {
  NewsCommentPageModel.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NewsCommentModel.fromJson)
          .map((m) => m.toEntity())
          .toList(),
      nextCursor = json['nextCursor'] as String?;

  final List<NewsComment> items;
  final String? nextCursor;

  NewsCommentPage toEntity() =>
      NewsCommentPage(items: items, nextCursor: nextCursor);
}
