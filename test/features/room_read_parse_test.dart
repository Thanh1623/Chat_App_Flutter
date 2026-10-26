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
        'lastReadAt': '2026-10-26T10:00:00.000Z',
      },
    ]);
    expect(reads, hasLength(1));
    expect(reads.first.userId, 'u2');
    expect(reads.first.lastReadMessageId, 'm9');
    expect(reads.first.lastReadAt, DateTime.utc(2026, 10, 26, 10));
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

  test('splitMessageSeen lists who has and has not read through a message', () {
    const members = [
      MessageSeenPerson(userId: 'me', name: 'Me'),
      MessageSeenPerson(userId: 'sender', name: 'Sender'),
      MessageSeenPerson(userId: 'a', name: 'An'),
      MessageSeenPerson(userId: 'b', name: 'Bình'),
      MessageSeenPerson(userId: 'c', name: 'Chi'),
    ];
    final t0 = DateTime.utc(2026, 10, 26, 9);
    final t1 = DateTime.utc(2026, 10, 26, 10);
    final details = splitMessageSeen(
      members: members,
      reads: [
        RoomRead(
          userId: 'a',
          name: 'An',
          lastReadMessageId: 'm2',
          lastReadAt: t1,
        ),
        const RoomRead(userId: 'b', name: 'Bình', lastReadMessageId: 'm1'),
      ],
      messageId: 'm1',
      messageCreatedAt: t0,
      newestFirstIds: const ['m2', 'm1', 'm0'],
      myId: 'me',
      senderId: 'sender',
    );
    expect(details.seen.map((p) => p.userId), ['a', 'b']);
    expect(details.unseen.map((p) => p.userId), ['c']);
  });
}
