class RoomImageModel {
  const RoomImageModel({required this.id, required this.url});

  final String id;
  final String url;

  factory RoomImageModel.fromJson(Map<String, dynamic> json) {
    return RoomImageModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}
