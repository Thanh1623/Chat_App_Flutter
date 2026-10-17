import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRoomReads maps Nest read receipts', () {
    final reads = parseRoomReads([
      {
        'userId': 'u2',
        'name': 'Bình',
        'avatarUrl': '',
        'lastReadMessageId': 'm9',
      },
    ]);
    expect(reads, hasLength(1));
    expect(reads.first.userId, 'u2');
    expect(reads.first.lastReadMessageId, 'm9');
    expect(parseRoomReads(null), isEmpty);
    expect(
      parseRoomReads({
        'roomId': 'r1',
        'reads': [
          {'userId': 'u2', 'name': 'Bình', 'lastReadMessageId': 'm9'},
        ],
      }).single.userId,
      'u2',
    );
  });
}
