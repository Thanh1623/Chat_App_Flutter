import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';

class InboxSearchMessage {
  const InboxSearchMessage({
    required this.id,
    required this.roomId,
    required this.content,
    required this.authorName,
    required this.roomTitle,
    this.roomAvatarUrl = '',
    this.roomKind = 'direct',
    this.createdAt,
    this.peerUserId,
    this.canDelete = false,
  });

  final String id;
  final String roomId;
  final String content;
  final String authorName;
  final String roomTitle;
  final String roomAvatarUrl;
  final String roomKind;
  final DateTime? createdAt;
  final String? peerUserId;
  final bool canDelete;

  bool get isGroup => roomKind == 'group';

  factory InboxSearchMessage.fromJson(Map<String, dynamic> json) {
    return InboxSearchMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      roomTitle: json['roomTitle']?.toString() ?? '',
      roomAvatarUrl: json['roomAvatarUrl']?.toString() ?? '',
      roomKind: json['roomKind']?.toString() ?? 'direct',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      peerUserId: json['peerUserId']?.toString(),
      canDelete: json['canDelete'] == true,
    );
  }
}

class InboxSearchResult {
  const InboxSearchResult({
    this.users = const [],
    this.rooms = const [],
    this.messages = const [],
  });

  final List<ContactUser> users;
  final List<Conversation> rooms;
  final List<InboxSearchMessage> messages;

  bool get isEmpty => users.isEmpty && rooms.isEmpty && messages.isEmpty;
}
