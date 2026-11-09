import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';

class GalleryPhotoPage {
  const GalleryPhotoPage({
    required this.items,
    this.nextCursor,
  });

  final List<GalleryPhoto> items;
  final String? nextCursor;
}
