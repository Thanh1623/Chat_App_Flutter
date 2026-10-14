enum ConversationType { direct, group }

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.lastMessagePreview,
    required this.updatedAt,
    this.unreadCount = 0,
    this.canDelete = false,
    this.peerUserId,
  });

  final String id;
  final String title;
  final ConversationType type;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final int unreadCount;
  final bool canDelete;
  /// Người còn lại trong chat 1-1 (do BE tính theo viewer).
  final String? peerUserId;
}
