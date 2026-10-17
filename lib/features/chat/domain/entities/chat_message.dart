class ReactionUser {
  const ReactionUser({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String avatarUrl;
}

class MessageReaction {
  const MessageReaction({
    required this.emoji,
    required this.count,
    this.userIds = const [],
    this.users = const [],
  });

  final String emoji;
  final int count;
  final List<String> userIds;
  final List<ReactionUser> users;

  bool isMine(String? myId) {
    final id = myId?.trim() ?? '';
    return id.isNotEmpty && userIds.contains(id);
  }
}

const reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.role,
    required this.content,
    required this.createdAt,
    this.userId,
    this.imageId,
    this.imageUrl,
    this.fileId,
    this.fileUrl,
    this.fileName,
    this.fileMimeType,
    this.fileSizeBytes,
    this.pinned = false,
    this.reactions = const [],
    this.replyTo,
  });

  final String id;
  final String roomId;
  final String? userId;
  final String authorName;
  final String authorAvatarUrl;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? imageId;
  final String? imageUrl;
  final String? fileId;
  final String? fileUrl;
  final String? fileName;
  final String? fileMimeType;
  final int? fileSizeBytes;
  final bool pinned;
  final List<MessageReaction> reactions;
  final MessageReplyTo? replyTo;

  bool get isAgent => role == 'agent';
  bool get hasImage {
    final url = imageUrl?.trim() ?? '';
    return url.isNotEmpty;
  }

  bool get hasFile {
    final url = fileUrl?.trim() ?? '';
    return url.isNotEmpty;
  }
}

class MessageReplyTo {
  const MessageReplyTo({
    required this.id,
    required this.authorName,
    this.content = '',
    this.imageUrl,
    this.recalled = false,
  });

  final String id;
  final String authorName;
  final String content;
  final String? imageUrl;
  final bool recalled;

  String get preview {
    if (recalled) return 'Tin đã thu hồi';
    final text = content.trim();
    if (text.isNotEmpty) return text;
    if ((imageUrl ?? '').trim().isNotEmpty) return 'Ảnh';
    return 'Tin nhắn';
  }
}
