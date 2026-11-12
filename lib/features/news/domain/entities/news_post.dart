import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';

enum NewsPostStatus { draft, published }

class NewsPost {
  const NewsPost({
    required this.id,
    required this.title,
    required this.blocks,
    required this.images,
    required this.status,
    required this.updatedAtIso,
    this.cover,
    this.publishedAt,
  });

  final String id;
  final String title;
  final List<NewsBlock> blocks;
  final List<NewsImage> images;
  final NewsImage? cover;
  final NewsPostStatus status;
  final String? publishedAt; // ISO từ API
  final String updatedAtIso;
}
