import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/conversations/domain/entities/room_public.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/profile/presentation/profile_avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showGroupSettingsSheet({
  required BuildContext context,
  required String roomId,
  required String name,
  required String avatarUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: GroupSettingsSheet(
        roomId: roomId,
        name: name,
        avatarUrl: avatarUrl,
      ),
    ),
  );
}

class GroupSettingsSheet extends ConsumerStatefulWidget {
  const GroupSettingsSheet({
    super.key,
    required this.roomId,
    required this.name,
    required this.avatarUrl,
  });

  final String roomId;
  final String name;
  final String avatarUrl;

  @override
  ConsumerState<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends ConsumerState<GroupSettingsSheet> {
  late final TextEditingController _name;
  late String _avatarUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _avatarUrl = widget.avatarUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _apply(RoomPublic room) {
    ref.read(conversationsInboxProvider.notifier).applyRoomMeta(
          id: widget.roomId,
          title: room.name,
          avatarUrl: room.avatarUrl,
        );
    if (room.avatarUrl.isNotEmpty) {
      imageCache.evict(NetworkImage(room.avatarUrl));
      _avatarUrl = room.avatarUrl;
    }
  }

  Future<void> _saveName() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên nhóm không được trống')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final room = await ref
          .read(conversationsRepositoryProvider)
          .updateRoomName(widget.roomId, name);
      if (!mounted) return;
      _apply(room);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await pickProfileImageFile();
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = true);
      final room = await ref
          .read(conversationsRepositoryProvider)
          .uploadRoomAvatar(
            roomId: widget.roomId,
            bytes: bytes,
            filename: file.name.isNotEmpty ? file.name : 'avatar.jpg',
          );
      if (!mounted) return;
      setState(() {
        _apply(room);
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh nhóm')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thông tin nhóm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _busy ? null : _pickAvatar,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ChatMessageAvatar(
                    displayName: _name.text.trim().isEmpty
                        ? widget.name
                        : _name.text.trim(),
                    avatarUrl: _avatarUrl,
                    radius: 40,
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đổi ảnh nhóm',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveName(),
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _saveName,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu tên nhóm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
