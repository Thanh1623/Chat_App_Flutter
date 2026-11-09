import 'package:chat_app/features/gallery/domain/entities/gallery_access.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo_page.dart';

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

DateTime _parseDateRequired(dynamic value) {
  return _parseDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class GalleryAccessModel {
  GalleryAccessModel.fromJson(Map<String, dynamic> json)
      : canReview = json['canReview'] == true,
        canReadPrivate = json['canReadPrivate'] == true;

  final bool canReview;
  final bool canReadPrivate;

  GalleryAccess toEntity() =>
      GalleryAccess(canReview: canReview, canReadPrivate: canReadPrivate);
}

class GalleryAlbumModel {
  GalleryAlbumModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        name = json['name'] as String? ?? '',
        description = json['description'] as String? ?? '',
        coverUrl = json['coverUrl'] as String?,
        photoCount = (json['photoCount'] as num?)?.toInt() ?? 0;

  final String id;
  final String name;
  final String description;
  final String? coverUrl;
  final int photoCount;

  GalleryAlbum toEntity() => GalleryAlbum(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
        photoCount: photoCount,
      );
}

class GalleryUploaderModel {
  GalleryUploaderModel.fromJson(Map<String, dynamic>? json)
      : id = json?['id'] as String? ?? '',
        name = json?['name'] as String? ?? '',
        avatarUrl = json?['avatarUrl'] as String? ?? '';

  final String id;
  final String name;
  final String avatarUrl;

  GalleryUploader? toEntity() {
    if (id.isEmpty) return null;
    return GalleryUploader(id: id, name: name, avatarUrl: avatarUrl);
  }
}

class GalleryPhotoModel {
  GalleryPhotoModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        url = json['url'] as String? ?? '',
        thumbUrl = json['thumbUrl'] as String? ?? '',
        filename = json['filename'] as String? ?? '',
        bytes = (json['bytes'] as num?)?.toInt() ?? 0,
        caption = json['caption'] as String? ?? '',
        status = json['status'] as String? ?? '',
        visibility = json['visibility'] as String? ?? 'public',
        albumId = json['albumId'] as String?,
        uploader = GalleryUploaderModel.fromJson(
          json['uploader'] as Map<String, dynamic>?,
        ),
        rejectReason = json['rejectReason'] as String?,
        reviewedAt = _parseDate(json['reviewedAt']),
        createdAt = _parseDateRequired(json['createdAt']),
        canEdit = json['canEdit'] == true,
        canEditDetails = json['canEditDetails'] == true,
        canDelete = json['canDelete'] == true;

  final String id;
  final String url;
  final String thumbUrl;
  final String filename;
  final int bytes;
  final String caption;
  final String status;
  final String visibility;
  final String? albumId;
  final GalleryUploaderModel uploader;
  final String? rejectReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final bool canEdit;
  final bool canEditDetails;
  final bool canDelete;

  GalleryPhoto toEntity() => GalleryPhoto(
        id: id,
        url: url,
        thumbUrl: thumbUrl,
        filename: filename,
        bytes: bytes,
        caption: caption,
        status: status,
        visibility: visibility,
        albumId: albumId,
        uploader: uploader.toEntity(),
        rejectReason: rejectReason,
        reviewedAt: reviewedAt,
        createdAt: createdAt,
        canEdit: canEdit,
        canEditDetails: canEditDetails,
        canDelete: canDelete,
      );
}

class GalleryPhotoPageModel {
  GalleryPhotoPageModel.fromJson(Map<String, dynamic> json)
      : items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GalleryPhotoModel.fromJson)
            .map((m) => m.toEntity())
            .toList(),
        nextCursor = json['nextCursor'] as String?;

  final List<GalleryPhoto> items;
  final String? nextCursor;

  GalleryPhotoPage toEntity() =>
      GalleryPhotoPage(items: items, nextCursor: nextCursor);
}
