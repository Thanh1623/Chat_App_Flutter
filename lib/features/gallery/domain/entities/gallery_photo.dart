class GalleryUploader {
  const GalleryUploader({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;
}

class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.filename,
    required this.bytes,
    required this.caption,
    required this.status,
    required this.visibility,
    this.albumId,
    this.uploader,
    this.rejectReason,
    this.reviewedAt,
    required this.createdAt,
    required this.canEdit,
    required this.canEditDetails,
    required this.canDelete,
  });

  final String id;
  final String url;
  final String thumbUrl;
  final String filename;
  final int bytes;
  final String caption;
  final String status;
  final String visibility;
  final String? albumId;
  final GalleryUploader? uploader;
  final String? rejectReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final bool canEdit;
  final bool canEditDetails;
  final bool canDelete;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isPrivate => visibility == 'private';
}
