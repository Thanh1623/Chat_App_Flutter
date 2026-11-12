import 'package:chat_app/features/news/data/models/news_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NewsPostPageModel parses feed item', () {
    final page = NewsPostPageModel.fromJson({
      'items': [
        {
          'id': 'p1',
          'title': 'Hello',
          'excerpt': 'Nội dung',
          'blocks': [
            {'type': 'paragraph', 'text': 'Nội dung'},
          ],
          'images': [],
          'cover': {
            'id': 'img1',
            'displayUrl': 'https://cdn/a.jpg',
            'thumbUrl': 'https://cdn/a_t.jpg',
          },
          'author': {'id': 'u1', 'name': 'An', 'avatarUrl': ''},
          'source': null,
          'publishedAt': '2026-11-11T10:00:00.000Z',
          'updatedAt': '2026-11-11T10:00:00.000Z',
          'reactions': {'total': 5, 'top': ['like'], 'mine': 'like'},
          'commentCount': 2,
          'comments': {
            'items': [
              {
                'id': 'c1',
                'postId': 'p1',
                'parentId': null,
                'body': 'Hay',
                'author': {'id': 'u2', 'name': 'Bình', 'avatarUrl': ''},
                'createdAt': '2026-11-11T11:00:00.000Z',
                'replyCount': 0,
                'replies': [],
              },
            ],
            'nextCursor': null,
          },
        },
      ],
      'nextCursor': 'c1',
    }).toEntity();

    expect(page.items.single.id, 'p1');
    expect(page.items.single.likeCount, 5);
    expect(page.items.single.likedByMe, isTrue);
    expect(page.items.single.previewComments.length, 1);
    expect(page.nextCursor, 'c1');
  });
}
