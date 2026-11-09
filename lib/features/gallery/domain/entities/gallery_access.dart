class GalleryAccess {
  const GalleryAccess({
    required this.canReview,
    required this.canReadPrivate,
  });

  final bool canReview;
  final bool canReadPrivate;
}
