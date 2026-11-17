enum NewsNotificationType { like, comment, reply }

class NewsNotificationActor {
  const NewsNotificationActor({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String avatarUrl;
}

class NewsNotification {
  const NewsNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.actor,
    required this.postId,
    this.readAt,
    this.postTitle = '',
    this.postExcerpt = '',
    this.commentBody,
  });

  final String id;
  final NewsNotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final NewsNotificationActor actor;
  final String postId;
  final String postTitle;
  final String postExcerpt;
  final String? commentBody;

  bool get unread => readAt == null;
}

class NewsNotificationPage {
  const NewsNotificationPage({required this.items, this.nextCursor});

  final List<NewsNotification> items;
  final String? nextCursor;
}
