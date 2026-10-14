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
        fileId: fileId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileMimeType: fileMimeType,
        fileSizeBytes: fileSizeBytes,
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
      fileId: json['fileId']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileMimeType: json['fileMimeType']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is num
          ? (json['fileSizeBytes'] as num).toInt()
          : int.tryParse(json['fileSizeBytes']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
