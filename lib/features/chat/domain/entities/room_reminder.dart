/** Room Reminder để đặt lời nhắc cho phòng */
class RoomReminder {
  const RoomReminder({
    required this.id,
    required this.roomId,
    required this.title,
    required this.remindAt,
    required this.repeat,
    required this.creatorId,
    this.creatorName = '',
  });

  final String id;
  final String roomId;
  final String title;
  final DateTime remindAt;
  final String repeat;
  final String creatorId;
  final String creatorName;

  bool get isRepeating => repeat == 'daily' || repeat == 'weekly';

  String get repeatLabel => switch (repeat) {
    'daily' => 'Hằng ngày',
    'weekly' => 'Hằng tuần',
    _ => 'Không lặp',
  };
}
