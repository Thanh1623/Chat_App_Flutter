import 'package:chat_app/features/news/domain/entities/news_notification.dart';

class NewsNotificationModel {
  NewsNotificationModel.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      type = _type(json['type']?.toString()),
      createdAt =
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readAt = DateTime.tryParse(json['readAt']?.toString() ?? ''),
      actor = _actor(json['actor']),
      postId = _postId(json['post']),
      postTitle = _postField(json['post'], 'title'),
      postExcerpt = _postField(json['post'], 'excerpt'),
      commentBody = _commentBody(json['comment']);

  final String id;
  final NewsNotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final NewsNotificationActor actor;
  final String postId;
  final String postTitle;
  final String postExcerpt;
  final String? commentBody;

  static NewsNotificationType _type(String? raw) {
    return switch (raw) {
      'reply' => NewsNotificationType.reply,
      'comment' => NewsNotificationType.comment,
      _ => NewsNotificationType.like,
    };
  }

  static NewsNotificationActor _actor(dynamic raw) {
    if (raw is! Map) {
      return const NewsNotificationActor(id: '', name: 'Người dùng');
    }
    final map = Map<String, dynamic>.from(raw);
    return NewsNotificationActor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Người dùng',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
    );
  }

  static String _postId(dynamic raw) {
    if (raw is! Map) return '';
    return Map<String, dynamic>.from(raw)['id']?.toString() ?? '';
  }

  static String _postField(dynamic raw, String key) {
    if (raw is! Map) return '';
    return Map<String, dynamic>.from(raw)[key]?.toString() ?? '';
  }

  static String? _commentBody(dynamic raw) {
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw)['body']?.toString();
  }

  NewsNotification toEntity() => NewsNotification(
    id: id,
    type: type,
    createdAt: createdAt,
    readAt: readAt,
    actor: actor,
    postId: postId,
    postTitle: postTitle,
    postExcerpt: postExcerpt,
    commentBody: commentBody,
  );
}

class NewsNotificationPageModel {
  NewsNotificationPageModel.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NewsNotificationModel.fromJson)
          .map((m) => m.toEntity())
          .toList(),
      nextCursor = json['nextCursor'] as String?;

  final List<NewsNotification> items;
  final String? nextCursor;

  NewsNotificationPage toEntity() =>
      NewsNotificationPage(items: items, nextCursor: nextCursor);
}
