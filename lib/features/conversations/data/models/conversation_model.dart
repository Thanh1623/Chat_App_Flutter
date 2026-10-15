import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.type,
    required this.lastMessagePreview,
    required this.updatedAt,
    this.unreadCount = 0,
    this.canDelete = false,
    this.peerUserId,
    this.avatarUrl = '',
  });

  final String id;
  final String title;
  final ConversationType type;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final int unreadCount;
  final bool canDelete;
  final String? peerUserId;
  final String avatarUrl;

  Conversation toEntity() => Conversation(
    id: id,
    title: title,
    type: type,
    lastMessagePreview: lastMessagePreview,
    updatedAt: updatedAt,
    unreadCount: unreadCount,
    canDelete: canDelete,
    peerUserId: peerUserId,
    avatarUrl: avatarUrl,
  );

  static String _lastMessagePreviewFromJson(Map<String, dynamic> json) {
    final direct = json['lastMessagePreview']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final flat = json['lastMessage']?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    final nested = json['lastMessage'];
    if (nested is Map) {
      final content = nested['content']?.toString() ?? '';
      if (content.isNotEmpty) return content;
    }
    return '';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final typeRaw =
        json['type']?.toString() ?? json['kind']?.toString() ?? 'direct';
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      type: typeRaw == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      lastMessagePreview: _lastMessagePreviewFromJson(json),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      canDelete: json['canDelete'] == true,
      peerUserId: json['peerUserId']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}
