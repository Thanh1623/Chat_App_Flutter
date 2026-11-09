import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_photo_viewer.dart';
import 'package:flutter/material.dart';

class GalleryPhotoGrid extends StatelessWidget {
  const GalleryPhotoGrid({
    super.key,
    required this.photos,
    required this.onLoadMore,
    required this.hasMore,
    required this.loadingMore,
    this.badgeBuilder,
  });

  final List<GalleryPhoto> photos;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool loadingMore;
  final Widget Function(GalleryPhoto photo)? badgeBuilder;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Chưa có ảnh'),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            !loadingMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: photos.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= photos.length) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final photo = photos[index];
          return _PhotoCell(
            photo: photo,
            badge: badgeBuilder?.call(photo),
            onTap: () => openGalleryPhotoViewer(
              context,
              photos: photos,
              initialPhotoId: photo.id,
            ),
          );
        },
      ),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.photo,
    required this.onTap,
    this.badge,
  });

  final GalleryPhoto photo;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8E8E8),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE0E0E0),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            if (photo.isPrivate || badge != null)
              Positioned(
                left: 4,
                top: 4,
                right: 4,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (photo.isPrivate)
                      _MiniTag(
                        label: 'Private',
                        color: Colors.amber.shade800,
                      ),
                    if (badge != null) badge!,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Widget galleryStatusBadge(GalleryPhoto photo) {
  if (photo.isPending) {
    return _MiniTag(label: 'Chờ duyệt', color: Colors.blue.shade700);
  }
  if (photo.isApproved) {
    return _MiniTag(label: 'Đã duyệt', color: Colors.green.shade700);
  }
  return _MiniTag(label: 'Từ chối', color: Colors.red.shade700);
}
