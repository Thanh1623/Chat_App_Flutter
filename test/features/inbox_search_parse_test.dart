import 'package:chat_app/features/conversations/data/datasources/conversations_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseInboxSearch maps users, rooms, messages', () {
    final result = parseInboxSearch({
      'users': [
        {'id': 'u1', 'name': 'An', 'email': 'an@vcb.vn', 'team': 'sale'},
      ],
      'rooms': [
        {'id': 'g1', 'name': 'VIP 1', 'type': 'group', 'avatarUrl': ''},
      ],
      'messages': [
        {
          'id': 'm1',
          'roomId': 'r1',
          'content': 'hello file',
          'authorName': 'Bình',
          'roomTitle': 'Sale Hai',
          'roomKind': 'direct',
        },
      ],
    });
    expect(result.users.single.name, 'An');
    expect(result.rooms.single.title, 'VIP 1');
    expect(result.messages.single.content, 'hello file');
    expect(parseInboxSearch(null).isEmpty, isTrue);
  });
}
