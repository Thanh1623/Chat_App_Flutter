class RoomRead {
  const RoomRead({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
    this.lastReadMessageId,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final String? lastReadMessageId;

  factory RoomRead.fromJson(Map<String, dynamic> json) {
    return RoomRead(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      lastReadMessageId: json['lastReadMessageId']?.toString(),
    );
  }
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
