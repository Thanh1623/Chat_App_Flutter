class RoomMediaImage {
  const RoomMediaImage({
    required this.id,
    required this.url,
    this.filename = '',
    this.createdAt,
  });

  final String id;
  final String url;
  final String filename;
  final DateTime? createdAt;

  factory RoomMediaImage.fromJson(Map<String, dynamic> json) {
    return RoomMediaImage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class RoomMediaFile {
  const RoomMediaFile({
    required this.id,
    required this.url,
    this.filename = 'file',
    this.mimeType = '',
    this.sizeBytes = 0,
    this.createdAt,
  });

  final String id;
  final String url;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  factory RoomMediaFile.fromJson(Map<String, dynamic> json) {
    return RoomMediaFile(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? 'file',
      mimeType: json['mimeType']?.toString() ?? '',
      sizeBytes: json['sizeBytes'] is num
          ? (json['sizeBytes'] as num).toInt()
          : int.tryParse(json['sizeBytes']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class RoomMediaLink {
  const RoomMediaLink({
    required this.url,
    this.messageId = '',
    this.authorName = '',
    this.createdAt,
  });

  final String url;
  final String messageId;
  final String authorName;
  final DateTime? createdAt;

  factory RoomMediaLink.fromJson(Map<String, dynamic> json) {
    return RoomMediaLink(
      url: json['url']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

List<RoomMediaImage> parseRoomImages(dynamic data) =>
    _mapMedia(data, RoomMediaImage.fromJson);

List<RoomMediaFile> parseRoomFiles(dynamic data) =>
    _mapMedia(data, RoomMediaFile.fromJson);

List<RoomMediaLink> parseRoomLinks(dynamic data) =>
    _mapMedia(data, RoomMediaLink.fromJson);

List<T> _mapMedia<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  final list = data is List ? data : const [];
  return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
}
