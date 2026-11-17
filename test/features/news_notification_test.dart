import 'package:chat_app/features/news/data/models/news_notification_model.dart';
import 'package:chat_app/features/news/domain/entities/news_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses comment notification', () {
    final item = NewsNotificationModel.fromJson({
      'id': 'n1',
      'type': 'comment',
      'createdAt': '2026-11-12T10:00:00.000Z',
      'readAt': null,
      'actor': {'id': 'u1', 'name': 'An', 'avatarUrl': ''},
      'post': {
        'id': 'p1',
        'title': 'Tiêu đề',
        'excerpt': 'Đoạn mở',
      },
      'comment': {'id': 'c1', 'body': 'Hay quá'},
    }).toEntity();

    expect(item.type, NewsNotificationType.comment);
    expect(item.actor.name, 'An');
    expect(item.postId, 'p1');
    expect(item.commentBody, 'Hay quá');
    expect(item.unread, isTrue);
  });
}
