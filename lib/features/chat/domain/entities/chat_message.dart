class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.authorName,
    required this.role,
    required this.content,
    required this.createdAt,
    this.userId,
    this.imageId,
    this.imageUrl,
  });

  final String id;
  final String roomId;
  final String? userId;
  final String authorName;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? imageId;
  final String? imageUrl;

  bool get isAgent => role == 'agent';
  bool get hasImage {
    final url = imageUrl?.trim() ?? '';
    return url.isNotEmpty;
  }
}
