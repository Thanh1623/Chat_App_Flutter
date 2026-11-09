import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/gallery/data/providers/gallery_repository_provider.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_photo.dart';
import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryReviewTab extends ConsumerStatefulWidget {
  const GalleryReviewTab({super.key});

  @override
  ConsumerState<GalleryReviewTab> createState() => _GalleryReviewTabState();
}

class _GalleryReviewTabState extends ConsumerState<GalleryReviewTab> {
  static const _feedKey = 'review';

  Future<void> _refresh() async {
    await ref.read(galleryPhotoFeedProvider(_feedKey).notifier).refresh();
    ref.invalidate(galleryAlbumsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(galleryPhotoFeedProvider(_feedKey));
    final albumsAsync = ref.watch(galleryAlbumsProvider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _refresh, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
      data: (state) {
        final albums = albumsAsync.valueOrNull ?? const <GalleryAlbum>[];
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 240,
                  child: Center(child: Text('Không có ảnh chờ duyệt')),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: state.items.length + (state.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final photo = state.items[index];
              return _ReviewCard(
                photo: photo,
                albums: albums,
                onView: () => openGalleryPhotoViewer(
                  context,
                  photos: state.items,
                  initialPhotoId: photo.id,
                ),
                onDone: () async {
                  invalidateGalleryLists(ref);
                  await _refresh();
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({
    required this.photo,
    required this.albums,
    required this.onView,
    required this.onDone,
  });

  final GalleryPhoto photo;
  final List<GalleryAlbum> albums;
  final VoidCallback onView;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  String? _albumId;
  String _visibility = 'public';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _albumId = widget.photo.albumId;
    _visibility = widget.photo.visibility;
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(galleryRepositoryProvider).approvePhoto(
            id: widget.photo.id,
            albumId: _albumId,
            visibility: _visibility,
          );
      await widget.onDone();
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối ảnh'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Lý do'),
          maxLength: 500,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      reasonCtrl.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(galleryRepositoryProvider).rejectPhoto(
            id: widget.photo.id,
            reason: reasonCtrl.text.trim(),
          );
      await widget.onDone();
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      reasonCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onView,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photo.thumbUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    photo.uploader?.name ?? 'Người dùng',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    photo.filename,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (photo.caption.isNotEmpty) Text(photo.caption),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: _albumId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Album',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Chưa xếp album'),
                      ),
                      for (final album in widget.albums)
                        DropdownMenuItem<String?>(
                          value: album.id,
                          child: Text(album.name),
                        ),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _albumId = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Public'),
                        selected: _visibility == 'public',
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _visibility = 'public'),
                      ),
                      ChoiceChip(
                        label: const Text('Private'),
                        selected: _visibility == 'private',
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _visibility = 'private'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy ? null : _approve,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Duyệt'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _reject,
                        child: const Text('Từ chối'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
