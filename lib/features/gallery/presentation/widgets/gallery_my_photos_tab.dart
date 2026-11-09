import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryMyPhotosTab extends ConsumerStatefulWidget {
  const GalleryMyPhotosTab({super.key});

  @override
  ConsumerState<GalleryMyPhotosTab> createState() =>
      _GalleryMyPhotosTabState();
}

class _GalleryMyPhotosTabState extends ConsumerState<GalleryMyPhotosTab> {
  String _status = 'all';

  String get _feedKey => 'mine:$_status';

  static const _filters = [
    ('all', 'Tất cả'),
    ('pending', 'Chờ duyệt'),
    ('approved', 'Đã duyệt'),
    ('rejected', 'Từ chối'),
  ];

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(galleryPhotoFeedProvider(_feedKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              for (final (value, label) in _filters) ...[
                FilterChip(
                  label: Text(label),
                  selected: _status == value,
                  onSelected: (_) => setState(() => _status = value),
                ),
                if (value != _filters.last.$1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (state) => RefreshIndicator(
              onRefresh: () =>
                  ref.read(galleryPhotoFeedProvider(_feedKey).notifier).refresh(),
              child: GalleryPhotoGrid(
                photos: state.items,
                hasMore: state.nextCursor != null,
                loadingMore: state.loadingMore,
                onLoadMore: () =>
                    ref.read(galleryPhotoFeedProvider(_feedKey).notifier).loadMore(),
                badgeBuilder: galleryStatusBadge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
