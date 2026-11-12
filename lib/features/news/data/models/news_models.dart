import 'package:chat_app/features/news/data/models/news_comment_model.dart';
import 'package:chat_app/features/news/data/models/news_post_model.dart';
import 'package:chat_app/features/news/domain/entities/news_card.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post_page.dart';

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

DateTime _publishedAt(Map<String, dynamic> json) {
  return _parseDate(json['publishedAt']) ??
      _parseDate(json['updatedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

class NewsCardModel {
  NewsCardModel.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      title = json['title']?.toString() ?? '',
      excerpt = json['excerpt']?.toString() ?? '',
      cover = parseCover(json['cover']),
      author = parseAuthor(json['author']),
      source = parseSource(json['source']),
      publishedAt = _publishedAt(json),
      updatedAt = _parseDate(json['updatedAt']) ?? _publishedAt(json),
      likeCount = reactionTotal(json['reactions']),
      commentCount = (json['commentCount'] as num?)?.toInt() ?? 0;

  final String id;
  final String title;
  final String excerpt;
  final NewsCoverImage? cover;
  final NewsAuthor? author;
  final NewsSource? source;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final int likeCount;
  final int commentCount;

  static NewsCoverImage? parseCover(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id']?.toString() ?? '';
    final display = map['displayUrl']?.toString() ?? '';
    if (id.isEmpty || display.isEmpty) return null;
    return NewsCoverImage(
      id: id,
      displayUrl: display,
      thumbUrl: map['thumbUrl']?.toString() ?? '',
    );
  }

  static NewsAuthor? parseAuthor(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    if (id.isEmpty && name.isEmpty) return null;
    return NewsAuthor(
      id: id,
      name: name,
      avatarUrl: map['avatarUrl']?.toString() ?? '',
    );
  }

  static NewsSource? parseSource(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['kind']?.toString() != 'facebook') return null;
    final name = map['name']?.toString() ?? 'Facebook';
    final url = map['url']?.toString() ?? '';
    return NewsSource(name: name, url: url);
  }

  static int reactionTotal(dynamic raw) {
    if (raw is! Map) return 0;
    return (raw['total'] as num?)?.toInt() ?? 0;
  }

  static bool reactionLikedByMe(dynamic raw) {
    if (raw is! Map) return false;
    return raw['mine'] != null;
  }

  NewsCard toEntity() => NewsCard(
    id: id,
    title: title,
    excerpt: excerpt,
    cover: cover,
    author: author,
    source: source,
    publishedAt: publishedAt,
    updatedAt: updatedAt,
    likeCount: likeCount,
    commentCount: commentCount,
  );
}

class NewsFeedItemModel {
  NewsFeedItemModel.fromJson(Map<String, dynamic> json)
    : card = NewsCardModel.fromJson(json),
      post = NewsPostModel.fromJson(json),
      likedByMe = NewsCardModel.reactionLikedByMe(json['reactions']),
      previewComments = _previewComments(json['comments']);

  final NewsCardModel card;
  final NewsPostModel post;
  final bool likedByMe;
  final List<NewsComment> previewComments;

  static List<NewsComment> _previewComments(dynamic raw) {
    if (raw is! Map) return const [];
    final items = raw['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NewsCommentModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }

  NewsFeedItem toEntity() {
    final coverEntity = card.cover != null
        ? NewsImage(
            id: card.cover!.id,
            displayUrl: card.cover!.displayUrl,
            thumbUrl: card.cover!.thumbUrl,
          )
        : post.cover;
    return NewsFeedItem(
      id: card.id,
      title: card.title,
      excerpt: card.excerpt,
      blocks: post.blocks,
      images: post.images,
      cover: coverEntity,
      author: card.author,
      source: card.source,
      publishedAt: card.publishedAt,
      likeCount: card.likeCount,
      commentCount: card.commentCount,
      likedByMe: likedByMe,
      previewComments: previewComments,
    );
  }
}

class NewsPostPageModel {
  NewsPostPageModel.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NewsFeedItemModel.fromJson)
          .map((m) => m.toEntity())
          .toList(),
      nextCursor = json['nextCursor'] as String?;

  final List<NewsFeedItem> items;
  final String? nextCursor;

  NewsPostPage toEntity() => NewsPostPage(items: items, nextCursor: nextCursor);
}
