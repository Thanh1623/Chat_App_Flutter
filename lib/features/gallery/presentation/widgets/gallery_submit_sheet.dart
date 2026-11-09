import 'dart:typed_data';

import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/chat/presentation/images/chat_image_picker.dart';
import 'package:chat_app/features/gallery/data/providers/gallery_repository_provider.dart';
import 'package:chat_app/features/gallery/domain/entities/gallery_album.dart';
import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

Future<void> showGallerySubmitSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _GallerySubmitSheet(),
  );
}

void _refreshGalleryAfterSubmit(WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    invalidateGalleryLists(ref);
    ref.read(galleryPhotoFeedProvider('mine:all').notifier).refresh();
  });
}

class _GallerySubmitSheet extends ConsumerStatefulWidget {
  const _GallerySubmitSheet();

  @override
  ConsumerState<_GallerySubmitSheet> createState() =>
      _GallerySubmitSheetState();
}

class _GallerySubmitSheetState extends ConsumerState<_GallerySubmitSheet> {
  final _caption = TextEditingController();
  String? _albumId;
  String _visibility = 'public';
  bool _sending = false;
  final List<XFile> _files = [];

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await pickChatImageFiles();
    if (!mounted) return;
    final room = galleryMaxPhotosPerSend - _files.length;
    if (room <= 0) {
      _toast('Tối đa $galleryMaxPhotosPerSend ảnh mỗi lần.');
      return;
    }
    setState(() {
      _files.addAll(
        picked.length <= room ? picked : picked.sublist(0, room),
      );
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit(List<GalleryAlbum> albums) async {
    if (_files.isEmpty) {
      _toast('Chọn ít nhất một ảnh.');
      return;
    }
    setState(() => _sending = true);
    final repo = ref.read(galleryRepositoryProvider);
    final caption = _caption.text.trim();
    var ok = 0;
    try {
      for (final file in _files) {
        final bytes = await file.readAsBytes();
        await repo.submitPhoto(
          bytes: bytes,
          filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
          albumId: _albumId,
          caption: caption.isEmpty ? null : caption,
          visibility: _visibility,
        );
        ok++;
      }
      if (!mounted) return;
      _toast('Đã gửi $ok ảnh.');
      Navigator.of(context).pop();
      _refreshGalleryAfterSubmit(ref);
    } on Failure catch (e) {
      if (!mounted) return;
      _toast(ok > 0 ? 'Gửi được $ok/${_files.length} ảnh. ${e.message}' : e.message);
    } catch (e) {
      if (!mounted) return;
      _toast('Không gửi được ảnh: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(galleryAlbumsProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gửi ảnh',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Chú thích (tuỳ chọn)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          albumsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Không tải được danh sách album'),
            data: (albums) => DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: _albumId,
              decoration: const InputDecoration(
                labelText: 'Album',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Chưa xếp album'),
                ),
                for (final album in albums)
                  DropdownMenuItem<String?>(
                    value: album.id,
                    child: Text(album.name),
                  ),
              ],
              onChanged: _sending ? null : (v) => setState(() => _albumId = v),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'public', label: Text('Public')),
              ButtonSegment(value: 'private', label: Text('Private')),
            ],
            selected: {_visibility},
            onSelectionChanged: _sending
                ? null
                : (values) => setState(() => _visibility = values.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in _files)
                _ThumbPreview(
                  file: file,
                  onRemove: _sending
                      ? null
                      : () => setState(() => _files.remove(file)),
                ),
              OutlinedButton.icon(
                onPressed: _sending || _files.length >= galleryMaxPhotosPerSend
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Chọn ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending
                ? null
                : () => albumsAsync.whenOrNull(
                      data: (albums) => _submit(albums),
                    ),
            child: _sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}

class _ThumbPreview extends StatelessWidget {
  const _ThumbPreview({required this.file, this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<List<int>>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 72,
                  height: 72,
                  child: ColoredBox(color: Color(0xFFE0E0E0)),
                );
              }
              return Image.memory(
                Uint8List.fromList(snapshot.data!),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
