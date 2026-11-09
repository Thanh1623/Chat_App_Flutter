import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryAlbumPhotosView extends ConsumerWidget {
  const GalleryAlbumPhotosView({
    super.key,
    required this.albumId,
    required this.title,
    required this.onBack,
  });

  final String albumId;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedKey = 'album:$albumId';
    final feed = ref.watch(galleryPhotoFeedProvider(feedKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (state) => RefreshIndicator(
              onRefresh: () =>
                  ref.read(galleryPhotoFeedProvider(feedKey).notifier).refresh(),
              child: GalleryPhotoGrid(
                photos: state.items,
                hasMore: state.nextCursor != null,
                loadingMore: state.loadingMore,
                onLoadMore: () => ref
                    .read(galleryPhotoFeedProvider(feedKey).notifier)
                    .loadMore(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
