import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_card.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';

class NewsFeedItem {
  const NewsFeedItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.blocks,
    required this.images,
    required this.publishedAt,
    required this.likeCount,
    required this.commentCount,
    this.cover,
    this.author,
    this.source,
    this.likedByMe = false,
    this.previewComments = const [],
  });

  final String id;
  final String title;
  final String excerpt;
  final List<NewsBlock> blocks;
  final List<NewsImage> images;
  final NewsImage? cover;
  final NewsAuthor? author;
  final NewsSource? source;
  final DateTime publishedAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final List<NewsComment> previewComments;
}
