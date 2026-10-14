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
    this.fileId,
    this.fileUrl,
    this.fileName,
    this.fileMimeType,
    this.fileSizeBytes,
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
  final String? fileId;
  final String? fileUrl;
  final String? fileName;
  final String? fileMimeType;
  final int? fileSizeBytes;

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
