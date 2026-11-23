import 'package:chat_app/features/chat/domain/entities/room_reminder.dart';

class RoomReminderModel {
  const RoomReminderModel({
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

  /** Chuyển đổi RoomReminderModel thành RoomReminder */
  RoomReminder toEntity() => RoomReminder(
    id: id,
    roomId: roomId,
    title: title,
    remindAt: remindAt,
    repeat: repeat,
    creatorId: creatorId,
    creatorName: creatorName,
  );

  /** Chuyển đổi JSON thành RoomReminderModel */
  factory RoomReminderModel.fromJson(Map<String, dynamic> json) {
    return RoomReminderModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      remindAt:
          DateTime.tryParse(json['remindAt']?.toString() ?? '') ??
          DateTime.now(),
      repeat: json['repeat']?.toString() ?? 'none',
      creatorId: json['creatorId']?.toString() ?? '',
      creatorName: json['creatorName']?.toString() ?? '',
    );
  }
}
