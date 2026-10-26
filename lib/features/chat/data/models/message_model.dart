import 'package:chat_app/features/chat/domain/entities/chat_message.dart';

class MessageModel {
  const MessageModel({
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
    this.recalled = false,
    this.reactions = const [],
    this.replyTo,
    this.type = 'text',
    this.task,
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
  final bool recalled;
  final List<MessageReaction> reactions;
  final MessageReplyTo? replyTo;
  final String type;
  final MessageTask? task;
  ChatMessage toEntity() => ChatMessage(
    id: id,
    roomId: roomId,
    userId: userId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
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
    pinned: pinned,
    recalled: recalled,
    reactions: reactions,
    replyTo: replyTo,
    type: type,
    task: task,
  );

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      authorName: json['authorName']?.toString() ?? '',
      authorAvatarUrl: json['authorAvatarUrl']?.toString() ?? '',
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
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      pinned: json['pinned'] == true,
      recalled: json['recalled'] == true,
      reactions: _reactionsFromJson(json['reactions']),
      replyTo: _replyToFromJson(json['replyTo']),
      type: json['type']?.toString() ?? 'text',
      task: _taskFromJson(json['task']),
    );
  }
}

MessageReplyTo? _replyToFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['id']?.toString() ?? '';
  if (id.isEmpty) return null;
  return MessageReplyTo(
    id: id,
    authorName: raw['authorName']?.toString() ?? '',
    content: raw['content']?.toString() ?? '',
    imageUrl: raw['imageUrl']?.toString(),
    recalled: raw['recalled'] == true,
  );
}

List<MessageReaction> _reactionsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final usersRaw = item['users'];
        final users = usersRaw is List
            ? usersRaw
                  .whereType<Map<String, dynamic>>()
                  .map((user) {
                    return ReactionUser(
                      id: user['id']?.toString() ?? '',
                      name: user['name']?.toString() ?? 'Thành viên',
                      avatarUrl: user['avatarUrl']?.toString() ?? '',
                    );
                  })
                  .where((user) => user.id.isNotEmpty)
                  .toList()
            : const <ReactionUser>[];
        final idsRaw = item['userIds'];
        final userIds = idsRaw is List
            ? idsRaw
                  .map((id) => id.toString())
                  .where((id) => id.isNotEmpty)
                  .toList()
            : users.map((user) => user.id).toList();
        final count = item['count'] is num
            ? (item['count'] as num).toInt()
            : int.tryParse(item['count']?.toString() ?? '') ?? userIds.length;
        return MessageReaction(
          emoji: item['emoji']?.toString() ?? '',
          count: count,
          userIds: userIds,
          users: users,
        );
      })
      .where((r) => r.emoji.isNotEmpty)
      .toList();
}

MessageTask? _taskFromJson(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['id']?.toString() ?? '';
  if (id.isEmpty) return null;
  return MessageTask(
    id: id,
    title: raw['title']?.toString() ?? '',
    notes: raw['notes']?.toString() ?? '',
    status: raw['status']?.toString() ?? 'open',
    dueAt: DateTime.tryParse(raw['dueAt']?.toString() ?? ''),
    creatorId: raw['creatorId']?.toString() ?? '',
    assigneeId: raw['assigneeId']?.toString() ?? '',
    creatorName: raw['creatorName']?.toString() ?? '',
    assigneeName: raw['assigneeName']?.toString() ?? '',
  );
}
