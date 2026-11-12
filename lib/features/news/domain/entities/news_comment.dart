import 'package:chat_app/features/news/domain/entities/news_card.dart';

class NewsComment {
  const NewsComment({
    required this.id,
    required this.postId,
    required this.body,
    this.author,
    this.parentId,
    this.createdAt,
    this.replyCount = 0,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String? parentId;
  final String body;
  final NewsAuthor? author;
  final DateTime? createdAt;
  final int replyCount;
  final List<NewsComment> replies;
}

class NewsCommentPage {
  const NewsCommentPage({required this.items, this.nextCursor});

  final List<NewsComment> items;
  final String? nextCursor;
}
