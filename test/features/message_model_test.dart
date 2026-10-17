import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageModel parses Nest message JSON', () {
    final parsed = MessageModel.fromJson({
      'id': 'm1',
      'roomId': 'r1',
      'userId': 'u1',
      'authorName': 'Sale Một',
      'role': 'user',
      'content': 'Xin chào',
      'createdAt': '2026-10-09T08:00:00.000Z',
      'pinned': true,
      'recalled': false,
      'replyTo': {
        'id': 'm0',
        'authorName': 'An',
        'content': 'hi',
        'recalled': false,
      },
      'reactions': [
        {
          'emoji': '👍',
          'count': 2,
          'userIds': ['u1', 'u2'],
          'users': [
            {'id': 'u1', 'name': 'An', 'avatarUrl': ''},
            {'id': 'u2', 'name': 'Bình', 'avatarUrl': ''},
          ],
        },
      ],
    });

    expect(parsed.id, 'm1');
    expect(parsed.roomId, 'r1');
    expect(parsed.userId, 'u1');
    expect(parsed.content, 'Xin chào');
    expect(parsed.toEntity().isAgent, isFalse);
    expect(parsed.toEntity().pinned, isTrue);
    expect(parsed.toEntity().reactions, hasLength(1));
    expect(parsed.toEntity().reactions.first.emoji, '👍');
    expect(parsed.toEntity().reactions.first.isMine('u1'), isTrue);
    expect(parsed.toEntity().reactions.first.isMine('u9'), isFalse);
    expect(parsed.toEntity().reactions.first.users.first.name, 'An');
    expect(parsed.toEntity().replyTo?.id, 'm0');
    expect(parsed.toEntity().replyTo?.preview, 'hi');
    expect(parsed.toEntity().recalled, isFalse);
    expect(
      MessageModel.fromJson({'id': 'm2', 'recalled': true}).toEntity().recalled,
      isTrue,
    );
  });
}
