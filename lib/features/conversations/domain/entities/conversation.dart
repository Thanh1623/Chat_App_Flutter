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
    this.avatarUrl = '',
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
  final String avatarUrl;

  Conversation copyWith({
    String? title,
    String? lastMessagePreview,
    DateTime? updatedAt,
    int? unreadCount,
    bool? canDelete,
    String? peerUserId,
    String? avatarUrl,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      type: type,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      canDelete: canDelete ?? this.canDelete,
      peerUserId: peerUserId ?? this.peerUserId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
