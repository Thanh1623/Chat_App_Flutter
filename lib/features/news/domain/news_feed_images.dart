import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';

/// Thứ tự ảnh giống web `feedImages`: cover trước, rồi khối image trong blocks.
List<String> newsFeedImageUrls({
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

  final orderedIds = <String>[];
  final seen = <String>{};

  if (cover != null) {
    seen.add(cover.id);
    orderedIds.add(cover.id);
  }

  for (final block in blocks) {
    if (block.type == NewsBlockType.image &&
        block.imageId != null &&
        imagesById.containsKey(block.imageId)) {
      final id = block.imageId!;
      if (!seen.contains(id)) {
        seen.add(id);
        orderedIds.add(id);
      }
    }
  }

  return orderedIds
      .map((id) {
        final img = imagesById[id];
        if (img == null) return '';
        return img.displayUrl.isNotEmpty ? img.displayUrl : img.url;
      })
      .where((url) => url.isNotEmpty)
      .toList();
}
