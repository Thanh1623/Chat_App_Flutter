import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post.dart';

class NewsImageModel {
  NewsImageModel.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      url = json['url']?.toString() ?? '',
      displayUrl = json['displayUrl']?.toString() ?? '',
      thumbUrl = json['thumbUrl']?.toString() ?? '';

  final String id;
  final String url;
  final String displayUrl;
  final String thumbUrl;

  NewsImage toEntity() =>
      NewsImage(id: id, url: url, displayUrl: displayUrl, thumbUrl: thumbUrl);
}

NewsBlock _blockFromJson(Map<String, dynamic> json) {
  final type = json['type']?.toString();
  return switch (type) {
    'heading' => NewsBlock.heading(json['text']?.toString() ?? ''),
    'image' => NewsBlock.image(
      imageId: json['imageId']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
    ),
    _ => NewsBlock.paragraph(json['text']?.toString() ?? ''),
  };
}

class NewsPostModel {
  NewsPostModel.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      title = json['title']?.toString() ?? '',
      updatedAtIso = json['updatedAt']?.toString() ?? '',
      publishedAt = json['publishedAt']?.toString(),
      status = json['status']?.toString() == 'published'
          ? NewsPostStatus.published
          : NewsPostStatus.draft,
      blocks = (json['blocks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_blockFromJson)
          .toList(),
      images = (json['images'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => NewsImageModel.fromJson(e).toEntity())
          .toList(),
      cover = _cover(json['cover']);

  final String id;
  final String title;
  final List<NewsBlock> blocks;
  final List<NewsImage> images;
  final NewsImage? cover;
  final NewsPostStatus status;
  final String? publishedAt;
  final String updatedAtIso;

  static NewsImage? _cover(dynamic raw) {
    if (raw is! Map) return null;
    return NewsImageModel.fromJson(Map<String, dynamic>.from(raw)).toEntity();
  }

  NewsPost toEntity() => NewsPost(
    id: id,
    title: title,
    blocks: blocks,
    images: images,
    cover: cover,
    status: status,
    publishedAt: publishedAt,
    updatedAtIso: updatedAtIso,
  );
}
