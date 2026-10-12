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
    });

    expect(parsed.id, 'm1');
    expect(parsed.roomId, 'r1');
    expect(parsed.userId, 'u1');
    expect(parsed.content, 'Xin chào');
    expect(parsed.toEntity().isAgent, isFalse);
  });
}
