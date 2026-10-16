import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMessagesPage reads Nest {data, meta} and legacy list', () {
    final paged = parseMessagesPage({
      'data': [
        {
          'id': 'm1',
          'roomId': 'r1',
          'authorName': 'A',
          'role': 'user',
          'content': 'hi',
          'createdAt': '2026-10-16T08:00:00.000Z',
        },
      ],
      'meta': {
        'hasMore': true,
        'nextCursor': '2026-10-16T08:00:00.000Z',
      },
    });
    expect(paged.items, hasLength(1));
    expect(paged.items.first.id, 'm1');
    expect(paged.hasMore, isTrue);
    expect(paged.nextCursor, '2026-10-16T08:00:00.000Z');

    final legacy = parseMessagesPage([
      {
        'id': 'm2',
        'roomId': 'r1',
        'authorName': 'A',
        'role': 'user',
        'content': 'old',
        'createdAt': '2026-10-16T07:00:00.000Z',
      },
    ]);
    expect(legacy.items, hasLength(1));
    expect(legacy.hasMore, isFalse);
    expect(legacy.nextCursor, isNull);
  });
}
