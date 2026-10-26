import 'package:chat_app/features/work/domain/entities/work_task.dart';

class WorkTaskModel {
  const WorkTaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.roomId,
    required this.creatorId,
    required this.assigneeId,
    this.notes = '',
    this.dueAt,
    this.roomName = '',
    this.messageId,
    this.creatorName = '',
    this.assigneeName = '',
  });

  final String id;
  final String title;
  final String notes;
  final String status;
  final DateTime? dueAt;
  final String roomId;
  final String roomName;
  final String? messageId;
  final String creatorId;
  final String assigneeId;
  final String creatorName;
  final String assigneeName;

  WorkTask toEntity() => WorkTask(
        id: id,
        title: title,
        notes: notes,
        status: status,
        dueAt: dueAt,
        roomId: roomId,
        roomName: roomName,
        messageId: messageId,
        creatorId: creatorId,
        assigneeId: assigneeId,
        creatorName: creatorName,
        assigneeName: assigneeName,
      );

  factory WorkTaskModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] is Map
        ? Map<String, dynamic>.from(json['creator'] as Map)
        : null;
    final assignee = json['assignee'] is Map
        ? Map<String, dynamic>.from(json['assignee'] as Map)
        : null;
    return WorkTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? ''),
      roomId: json['roomId']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      messageId: json['messageId']?.toString(),
      creatorId: json['creatorId']?.toString() ?? creator?['id']?.toString() ?? '',
      assigneeId:
          json['assigneeId']?.toString() ?? assignee?['id']?.toString() ?? '',
      creatorName: creator?['name']?.toString() ?? '',
      assigneeName: assignee?['name']?.toString() ?? '',
    );
  }
}
