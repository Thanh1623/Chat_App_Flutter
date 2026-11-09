import 'package:chat_app/features/gallery/domain/entities/gallery_access.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo_page.dart';

abstract interface class GalleryRepository {
  Future<GalleryAccess> fetchAccess();

  Future<List<GalleryAlbum>> fetchAlbums();

  Future<GalleryAlbum> createAlbum({
    required String name,
    String? description,
  });

  Future<GalleryAlbum> updateAlbum({
    required String id,
    String? name,
    String? description,
  });

  Future<void> deleteAlbum(String id);

  Future<GalleryPhotoPage> fetchApprovedPhotos({
    String? albumId,
    String? cursor,
  });

  Future<GalleryPhotoPage> fetchMyPhotos({
    String? status,
    String? cursor,
  });

  Future<GalleryPhotoPage> fetchReviewPhotos({String? cursor});

  Future<GalleryPhoto> submitPhoto({
    required List<int> bytes,
    required String filename,
    String? albumId,
    String? caption,
    String? visibility,
  });

  Future<GalleryPhoto> approvePhoto({
    required String id,
    String? albumId,
    String? visibility,
  });

  Future<GalleryPhoto> rejectPhoto({
    required String id,
    required String reason,
  });

  Future<void> deletePhoto(String id);
}
