import 'package:chat_app/features/chat/data/models/room_reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RoomReminderModel parses Nest create payload', () {
    final reminder = RoomReminderModel.fromJson({
      'id': 'rm1',
      'roomId': 'r1',
      'title': 'Họp standup',
      'remindAt': '2026-11-23T10:00:00.000Z',
      'repeat': 'daily',
      'creatorId': 'u1',
      'creatorName': 'Minh',
    }).toEntity();

    expect(reminder.id, 'rm1');
    expect(reminder.title, 'Họp standup');
    expect(reminder.isRepeating, isTrue);
    expect(reminder.repeatLabel, 'Hằng ngày');
    expect(reminder.creatorName, 'Minh');
  });
}
