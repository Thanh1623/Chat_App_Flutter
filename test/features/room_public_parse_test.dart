import 'package:chat_app/features/conversations/domain/entities/room_public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RoomPublic.fromJson maps Nest toPublicRoom', () {
    final room = RoomPublic.fromJson({
      'id': 'r1',
      'slug': 'vip-1',
      'name': 'VIP mới',
      'team': 'sale',
      'agentName': '',
      'avatarUrl': 'https://cdn.example/g.jpg',
    });
    expect(room.id, 'r1');
    expect(room.name, 'VIP mới');
    expect(room.avatarUrl, 'https://cdn.example/g.jpg');
    expect(RoomPublic.fromJson({'title': 'Fallback'}).name, 'Fallback');
  });
}
