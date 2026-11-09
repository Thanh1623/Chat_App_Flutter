import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/gallery/data/providers/gallery_repository_provider.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_album_photos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryAlbumsTab extends ConsumerStatefulWidget {
  const GalleryAlbumsTab({super.key, required this.canReview});

  final bool canReview;

  @override
  ConsumerState<GalleryAlbumsTab> createState() => _GalleryAlbumsTabState();
}

class _GalleryAlbumsTabState extends ConsumerState<GalleryAlbumsTab> {
  ({String id, String name})? _openAlbum;

  Future<void> _createOrEditAlbum({GalleryAlbum? album}) async {
    final nameCtrl = TextEditingController(text: album?.name ?? '');
    final descCtrl = TextEditingController(text: album?.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(album == null ? 'Tạo album' : 'Sửa album'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên album'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    if (saved != true || !mounted) return;

    final repo = ref.read(galleryRepositoryProvider);
    try {
      if (album == null) {
        await repo.createAlbum(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
      } else {
        await repo.updateAlbum(
          id: album.id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
      }
      ref.invalidate(galleryAlbumsProvider);
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteAlbum(GalleryAlbum album) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa album "${album.name}"?'),
        content: const Text(
          'Ảnh trong album không bị xóa, sẽ chuyển sang "Chưa xếp album".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(galleryRepositoryProvider).deleteAlbum(album.id);
      ref.invalidate(galleryAlbumsProvider);
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openAlbum != null) {
      return GalleryAlbumPhotosView(
        albumId: _openAlbum!.id,
        title: _openAlbum!.name,
        onBack: () => setState(() => _openAlbum = null),
      );
    }

    final albumsAsync = ref.watch(galleryAlbumsProvider);
    return albumsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (albums) {
        final shown = widget.canReview
            ? albums
            : albums.where((a) => a.photoCount > 0).toList();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(galleryAlbumsProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (widget.canReview)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _createOrEditAlbum(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo album'),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildListDelegate([
                    for (final album in shown)
                      _AlbumCard(
                        album: album,
                        canReview: widget.canReview,
                        onOpen: () => setState(
                          () => _openAlbum = (id: album.id, name: album.name),
                        ),
                        onEdit: () => _createOrEditAlbum(album: album),
                        onDelete: () => _deleteAlbum(album),
                      ),
                    _UnassignedAlbumCard(
                      onOpen: () => setState(
                        () => _openAlbum = (
                          id: galleryUnassignedAlbumId,
                          name: 'Chưa xếp album',
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.canReview,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final GalleryAlbum album;
  final bool canReview;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: album.coverUrl != null
                  ? Image.network(album.coverUrl!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.photo_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${album.photoCount} ảnh',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (canReview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Sửa album',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          tooltip: 'Xóa album',
                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                          onPressed: onDelete,
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

class _UnassignedAlbumCard extends StatelessWidget {
  const _UnassignedAlbumCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Chưa xếp album',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
