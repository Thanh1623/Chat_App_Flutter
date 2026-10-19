import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/data/providers/chat_repository_provider.dart';
import 'package:chat_app/features/chat/domain/entities/room_media.dart';
import 'package:chat_app/features/chat/presentation/files/chat_file_format.dart';
import 'package:chat_app/features/chat/presentation/widgets/pinned_messages_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showRoomMediaSheet({
  required BuildContext context,
  required String roomId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.75,
      child: RoomMediaSheet(roomId: roomId),
    ),
  );
}

class RoomMediaSheet extends ConsumerStatefulWidget {
  const RoomMediaSheet({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RoomMediaSheet> createState() => _RoomMediaSheetState();
}

class _RoomMediaSheetState extends ConsumerState<RoomMediaSheet> {
  List<RoomMediaImage>? _images;
  List<RoomMediaFile>? _files;
  List<RoomMediaLink>? _links;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final results = await Future.wait([
        repo.fetchRoomImages(widget.roomId),
        repo.fetchRoomFiles(widget.roomId),
        repo.fetchRoomLinks(widget.roomId),
      ]);
      if (!mounted) return;
      setState(() {
        _images = results[0] as List<RoomMediaImage>;
        _files = results[1] as List<RoomMediaFile>;
        _links = results[2] as List<RoomMediaLink>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 36,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
              ),
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: _tabLabel('Ảnh', _images?.length)),
              Tab(text: _tabLabel('File', _files?.length)),
              Tab(text: _tabLabel('Link', _links?.length)),
            ],
          ),
          Expanded(child: _body()),
        ],
      ),
      ),
    );
  }

  String _tabLabel(String label, int? count) =>
      count == null ? label : '$label ($count)';

  Widget _body() {
    if (_error != null && _images == null) {
      return ErrorView(message: _error.toString(), onRetry: _load);
    }
    if (_images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return TabBarView(
      children: [
        _ImagesGrid(images: _images!),
        _FilesList(files: _files!),
        _LinksList(links: _links!),
      ],
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  const _ImagesGrid({required this.images});

  final List<RoomMediaImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _EmptyHint(icon: Icons.image_outlined, text: 'Chưa có ảnh');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        return InkWell(
          onTap: () => _openImage(context, image.url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE8EAED),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilesList extends StatelessWidget {
  const _FilesList({required this.files});

  final List<RoomMediaFile> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const _EmptyHint(
        icon: Icons.insert_drive_file_outlined,
        text: 'Chưa có tệp',
      );
    }
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = files[index];
        final time = file.createdAt == null
            ? ''
            : pinnedMessageTime(file.createdAt!);
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(file.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (file.sizeBytes > 0) formatFileSize(file.sizeBytes),
              if (time.isNotEmpty) time,
            ].join(' · '),
          ),
          onTap: () => _openUrl(context, file.url, 'Không mở được tệp'),
        );
      },
    );
  }
}

class _LinksList extends StatelessWidget {
  const _LinksList({required this.links});

  final List<RoomMediaLink> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return const _EmptyHint(icon: Icons.link, text: 'Chưa có liên kết');
    }
    return ListView.separated(
      itemCount: links.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final link = links[index];
        final time = link.createdAt == null
            ? ''
            : pinnedMessageTime(link.createdAt!);
        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(link.url, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (link.authorName.isNotEmpty) link.authorName,
              if (time.isNotEmpty) time,
            ].join(' · '),
          ),
          onTap: () => _openUrl(context, link.url, 'Không mở được liên kết'),
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.black38),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

void _openImage(BuildContext context, String url) {
  if (url.trim().isEmpty) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: InteractiveViewer(
        child: Image.network(url, fit: BoxFit.contain),
      ),
    ),
  );
}

Future<void> _openUrl(BuildContext context, String url, String failMessage) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
  }
}
