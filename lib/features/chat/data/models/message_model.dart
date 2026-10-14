import 'package:chat_app/features/chat/domain/entities/chat_message.dart';

class MessageModel {
  const MessageModel({
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

  ChatMessage toEntity() => ChatMessage(
        id: id,
        roomId: roomId,
        userId: userId,
        authorName: authorName,
        role: role,
        content: content,
        createdAt: createdAt,
        imageId: imageId,
        imageUrl: imageUrl,
      );

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      authorName: json['authorName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      imageId: json['imageId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
