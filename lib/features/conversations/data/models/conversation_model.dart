import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.type,
    required this.lastMessagePreview,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  final String id;
  final String title;
  final ConversationType type;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final int unreadCount;

  Conversation toEntity() => Conversation(
        id: id,
        title: title,
        type: type,
        lastMessagePreview: lastMessagePreview,
        updatedAt: updatedAt,
        unreadCount: unreadCount,
      );

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type']?.toString() ?? 'direct';
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      type: typeRaw == 'group' ? ConversationType.group : ConversationType.direct,
      lastMessagePreview: json['lastMessagePreview']?.toString() ??
          json['lastMessage']?.toString() ??
          '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
