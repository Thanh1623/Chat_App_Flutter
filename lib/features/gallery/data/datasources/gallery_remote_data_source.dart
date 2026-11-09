import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/gallery/data/models/gallery_models.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_access.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo_page.dart';
import 'package:dio/dio.dart';

class GalleryRemoteDataSource {
  const GalleryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<GalleryAccess> fetchAccess() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.galleryAccess,
    );
    return GalleryAccessModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<List<GalleryAlbum>> fetchAlbums() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.galleryAlbums);
    final list = response.data;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GalleryAlbumModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }

  Future<GalleryAlbum> createAlbum({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.galleryAlbums,
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return GalleryAlbumModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryAlbum> updateAlbum({
    required String id,
    String? name,
    String? description,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.galleryAlbum(id),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      },
    );
    return GalleryAlbumModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<void> deleteAlbum(String id) async {
    await _dio.delete<void>(ApiEndpoints.galleryAlbum(id));
  }

  Future<GalleryPhotoPage> fetchApprovedPhotos({
    String? albumId,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.galleryPhotos,
      queryParameters: {
        if (albumId != null) 'albumId': albumId,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return GalleryPhotoPageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryPhotoPage> fetchMyPhotos({
    String? status,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.galleryPhotosMine,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return GalleryPhotoPageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryPhotoPage> fetchReviewPhotos({String? cursor}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.galleryReviewPhotos,
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return GalleryPhotoPageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryPhoto> submitPhoto({
    required List<int> bytes,
    required String filename,
    String? albumId,
    String? caption,
    String? visibility,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: imageMediaTypeFromFilename(filename),
      ),
      if (albumId != null && albumId.isNotEmpty) 'albumId': albumId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.galleryPhotos,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return GalleryPhotoModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryPhoto> approvePhoto({
    required String id,
    String? albumId,
    String? visibility,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.galleryPhotoApprove(id),
      data: {
        'albumId': albumId,
        if (visibility != null) 'visibility': visibility,
      },
    );
    return GalleryPhotoModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<GalleryPhoto> rejectPhoto({
    required String id,
    required String reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.galleryPhotoReject(id),
      data: {'reason': reason},
    );
    return GalleryPhotoModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<void> deletePhoto(String id) async {
    await _dio.delete<void>(ApiEndpoints.galleryPhoto(id));
  }
}
