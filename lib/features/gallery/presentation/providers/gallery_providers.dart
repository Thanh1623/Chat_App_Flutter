import 'package:chat_app/features/gallery/data/providers/gallery_repository_provider.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_access.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo_page.dart';
import 'package:chat_app/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const galleryUnassignedAlbumId = 'none';
const galleryMaxPhotosPerSend = 20;

final galleryAccessProvider = FutureProvider<GalleryAccess>((ref) {
  return ref.watch(galleryRepositoryProvider).fetchAccess();
});

final galleryAlbumsProvider = FutureProvider<List<GalleryAlbum>>((ref) {
  return ref.watch(galleryRepositoryProvider).fetchAlbums();
});

class GalleryPhotoFeedState {
  const GalleryPhotoFeedState({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<GalleryPhoto> items;
  final String? nextCursor;
  final bool loadingMore;

  GalleryPhotoFeedState copyWith({
    List<GalleryPhoto>? items,
    String? nextCursor,
    bool? loadingMore,
    bool clearCursor = false,
  }) {
    return GalleryPhotoFeedState(
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Feed key: `album:<id>`, `mine:<status|all>`, `review`
final galleryPhotoFeedProvider = AsyncNotifierProvider.family<
    GalleryPhotoFeedNotifier,
    GalleryPhotoFeedState,
    String>(GalleryPhotoFeedNotifier.new);

class GalleryPhotoFeedNotifier
    extends FamilyAsyncNotifier<GalleryPhotoFeedState, String> {
  GalleryRepository get _repo => ref.read(galleryRepositoryProvider);

  late String _feedKey;

  @override
  Future<GalleryPhotoFeedState> build(String feedKey) async {
    _feedKey = feedKey;
    final page = await _fetchPage();
    return GalleryPhotoFeedState(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await _fetchPage();
      return GalleryPhotoFeedState(
        items: page.items,
        nextCursor: page.nextCursor,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _fetchPage(cursor: cursor);
      state = AsyncData(
        GalleryPhotoFeedState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<GalleryPhotoPage> _fetchPage({String? cursor}) async {
    final key = _feedKey;
    if (key.startsWith('album:')) {
      final albumId = key.substring('album:'.length);
      return _repo.fetchApprovedPhotos(albumId: albumId, cursor: cursor);
    }
    if (key.startsWith('mine:')) {
      final status = key.substring('mine:'.length);
      return _repo.fetchMyPhotos(
        status: status == 'all' ? null : status,
        cursor: cursor,
      );
    }
    if (key == 'review') {
      return _repo.fetchReviewPhotos(cursor: cursor);
    }
    return const GalleryPhotoPage(items: []);
  }
}

void invalidateGalleryLists(WidgetRef ref) {
  ref.invalidate(galleryAlbumsProvider);
  // ponytail: không invalidate access — FutureProvider loading sẽ thay cả cây TabBar → _dependents.isEmpty
}
