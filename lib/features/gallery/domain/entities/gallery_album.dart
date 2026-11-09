class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.name,
    required this.description,
    this.coverUrl,
    required this.photoCount,
  });

  final String id;
  final String name;
  final String description;
  final String? coverUrl;
  final int photoCount;
}
