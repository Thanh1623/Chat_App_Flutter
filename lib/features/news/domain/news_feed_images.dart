import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';

/// Thứ tự ảnh giống web `feedImages`: cover trước, rồi khối image trong blocks.
List<NewsImage> newsFeedImages({
  required NewsImage? cover,
  required List<NewsBlock> blocks,
  required List<NewsImage> images,
}) {
  final imagesById = <String, NewsImage>{
    for (final img in images) img.id: img,
  };
  if (cover != null) {
    imagesById[cover.id] = cover;
  }

  final ordered = <NewsImage>[];
  final seen = <String>{};

  void add(String id) {
    final img = imagesById[id];
    if (img == null || !seen.add(id)) return;
    ordered.add(img);
  }

  if (cover != null) add(cover.id);
  for (final block in blocks) {
    if (block.type == NewsBlockType.image && block.imageId != null) {
      add(block.imageId!);
    }
  }
  return ordered;
}

List<String> newsFeedImageUrls({
  required NewsImage? cover,
  required List<NewsBlock> blocks,
  required List<NewsImage> images,
}) {
  return newsFeedImages(cover: cover, blocks: blocks, images: images)
      .map((img) => img.displayUrl.isNotEmpty ? img.displayUrl : img.url)
      .where((url) => url.isNotEmpty)
      .toList();
}
