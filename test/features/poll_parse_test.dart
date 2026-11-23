import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageModel parses Nest poll payload', () {
    final message = MessageModel.fromJson({
      'id': 'm1',
      'roomId': 'r1',
      'authorName': 'Minh',
      'role': 'user',
      'content': '📊 Họp lúc mấy?',
      'type': 'text',
      'createdAt': '2026-11-21T02:00:00.000Z',
      'poll': {
        'id': 'p1',
        'question': 'Họp lúc mấy?',
        'multiple': false,
        'allowAddOptions': true,
        'closesAt': '2026-11-22T10:00:00.000Z',
        'closed': false,
        'creatorId': 'u1',
        'totalVoters': 1,
        'options': [
          {
            'id': 'o1',
            'text': '9h',
            'count': 1,
            'voterIds': ['u2'],
          },
          {'id': 'o2', 'text': '14h', 'count': 0, 'voterIds': []},
        ],
      },
    }).toEntity();

    expect(message.isPoll, isTrue);
    expect(message.poll?.question, 'Họp lúc mấy?');
    expect(message.poll?.options, hasLength(2));
    expect(message.poll?.options.first.voterIds, ['u2']);
    expect(message.poll?.allowAddOptions, isTrue);
    expect(message.poll?.closed, isFalse);
  });

  test('recalled poll is not a poll card', () {
    final message = MessageModel.fromJson({
      'id': 'm1',
      'recalled': true,
      'poll': {
        'id': 'p1',
        'question': 'x',
        'multiple': false,
        'allowAddOptions': false,
        'closed': false,
        'creatorId': 'u1',
        'totalVoters': 0,
        'options': [],
      },
    }).toEntity();
    expect(message.isPoll, isFalse);
  });
}
