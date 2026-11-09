import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/gallery/data/datasources/gallery_remote_data_source.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_access.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo_page.dart';
import 'package:chat_app/features/gallery/domain/repositories/gallery_repository.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl(this._remote);

  final GalleryRemoteDataSource _remote;

  @override
  Future<GalleryAccess> fetchAccess() async {
    try {
      return await _remote.fetchAccess();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<GalleryAlbum>> fetchAlbums() async {
    try {
      return await _remote.fetchAlbums();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryAlbum> createAlbum({
    required String name,
    String? description,
  }) async {
    try {
      return await _remote.createAlbum(name: name, description: description);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryAlbum> updateAlbum({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      return await _remote.updateAlbum(
        id: id,
        name: name,
        description: description,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> deleteAlbum(String id) async {
    try {
      await _remote.deleteAlbum(id);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhotoPage> fetchApprovedPhotos({
    String? albumId,
    String? cursor,
  }) async {
    try {
      return await _remote.fetchApprovedPhotos(albumId: albumId, cursor: cursor);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhotoPage> fetchMyPhotos({
    String? status,
    String? cursor,
  }) async {
    try {
      return await _remote.fetchMyPhotos(status: status, cursor: cursor);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhotoPage> fetchReviewPhotos({String? cursor}) async {
    try {
      return await _remote.fetchReviewPhotos(cursor: cursor);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhoto> submitPhoto({
    required List<int> bytes,
    required String filename,
    String? albumId,
    String? caption,
    String? visibility,
  }) async {
    try {
      return await _remote.submitPhoto(
        bytes: bytes,
        filename: filename,
        albumId: albumId,
        caption: caption,
        visibility: visibility,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhoto> approvePhoto({
    required String id,
    String? albumId,
    String? visibility,
  }) async {
    try {
      return await _remote.approvePhoto(
        id: id,
        albumId: albumId,
        visibility: visibility,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<GalleryPhoto> rejectPhoto({
    required String id,
    required String reason,
  }) async {
    try {
      return await _remote.rejectPhoto(id: id, reason: reason);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> deletePhoto(String id) async {
    try {
      await _remote.deletePhoto(id);
    } catch (e) {
      throw mapException(e);
    }
  }
}
