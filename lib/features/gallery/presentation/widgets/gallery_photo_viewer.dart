import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:flutter/material.dart';

void openGalleryPhotoViewer(
  BuildContext context, {
  required List<GalleryPhoto> photos,
  required String initialPhotoId,
}) {
  final index = photos.indexWhere((p) => p.id == initialPhotoId);
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => GalleryPhotoViewer(
        photos: photos,
        initialIndex: index < 0 ? 0 : index,
      ),
    ),
  );
}

class GalleryPhotoViewer extends StatefulWidget {
  const GalleryPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<GalleryPhoto> photos;
  final int initialIndex;

  @override
  State<GalleryPhotoViewer> createState() => _GalleryPhotoViewerState();
}

class _GalleryPhotoViewerState extends State<GalleryPhotoViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.photos.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final item = widget.photos[index];
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      item.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (photo.caption.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                photo.caption,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
