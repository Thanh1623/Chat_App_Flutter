class RoomFileModel {
  const RoomFileModel({
    required this.id,
    required this.url,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String url;
  final String filename;
  final String mimeType;
  final int sizeBytes;

  factory RoomFileModel.fromJson(Map<String, dynamic> json) {
    return RoomFileModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? 'file',
      mimeType: json['mimeType']?.toString() ?? '',
      sizeBytes: json['sizeBytes'] is num
          ? (json['sizeBytes'] as num).toInt()
          : int.tryParse(json['sizeBytes']?.toString() ?? '') ?? 0,
    );
  }
}
