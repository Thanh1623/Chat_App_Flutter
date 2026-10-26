class RoomRead {
  const RoomRead({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
    this.lastReadMessageId,
    this.lastReadAt,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;

  factory RoomRead.fromJson(Map<String, dynamic> json) {
    return RoomRead(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      lastReadMessageId: json['lastReadMessageId']?.toString(),
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? ''),
    );
  }
}

class MessageSeenPerson {
  const MessageSeenPerson({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
  });

  final String userId;
  final String name;
  final String avatarUrl;
}

class MessageSeenDetails {
  const MessageSeenDetails({
    required this.seen,
    required this.unseen,
  });

  final List<MessageSeenPerson> seen;
  final List<MessageSeenPerson> unseen;
}

List<RoomRead> parseRoomReads(dynamic data) {
  final list = data is Map ? data['reads'] : data;
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((item) => RoomRead.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.userId.isNotEmpty)
      .toList();
}

/// Người đã đọc tới tin này (hoặc tin mới hơn). Bỏ sender và chính mình.
MessageSeenDetails splitMessageSeen({
  required Iterable<MessageSeenPerson> members,
  required List<RoomRead> reads,
  required String messageId,
  required DateTime messageCreatedAt,
  required List<String> newestFirstIds,
  String? myId,
  String? senderId,
}) {
  final skip = <String>{
    if (myId != null && myId.isNotEmpty) myId,
    if (senderId != null && senderId.isNotEmpty) senderId,
  };
  final readById = {for (final item in reads) item.userId: item};
  final seen = <MessageSeenPerson>[];
  final unseen = <MessageSeenPerson>[];

  for (final member in members) {
    if (member.userId.isEmpty || skip.contains(member.userId)) continue;
    final read = readById[member.userId];
    final person = MessageSeenPerson(
      userId: member.userId,
      name: (read != null && read.name.isNotEmpty) ? read.name : member.name,
      avatarUrl: (read != null && read.avatarUrl.isNotEmpty)
          ? read.avatarUrl
          : member.avatarUrl,
    );
    if (read != null &&
        _hasReadThrough(
          read: read,
          messageId: messageId,
          messageCreatedAt: messageCreatedAt,
          newestFirstIds: newestFirstIds,
        )) {
      seen.add(person);
    } else {
      unseen.add(person);
    }
  }

  return MessageSeenDetails(seen: seen, unseen: unseen);
}

bool _hasReadThrough({
  required RoomRead read,
  required String messageId,
  required DateTime messageCreatedAt,
  required List<String> newestFirstIds,
}) {
  if (read.lastReadMessageId == messageId) return true;
  if (read.lastReadAt != null &&
      !read.lastReadAt!.isBefore(messageCreatedAt)) {
    return true;
  }
  final lastIdx = newestFirstIds.indexOf(read.lastReadMessageId ?? '');
  final thisIdx = newestFirstIds.indexOf(messageId);
  if (lastIdx >= 0 && thisIdx >= 0) return lastIdx <= thisIdx;
  return false;
}
