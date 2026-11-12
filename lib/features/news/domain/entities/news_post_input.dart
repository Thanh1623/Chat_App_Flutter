import 'package:chat_app/features/news/domain/entities/news_block.dart';

class NewsPostInput {
  const NewsPostInput({
    required this.title,
    required this.blocks,
    required this.expectedUpdatedAt,
    this.coverImageId,
  });

  final String title;
  final List<NewsBlock> blocks;
  final String? coverImageId;
  final String expectedUpdatedAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'coverImageId': coverImageId,
    'expectedUpdatedAt': expectedUpdatedAt,
  };
}
