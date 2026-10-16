import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showGroupMembersSheet({
  required BuildContext context,
  required String roomId,
  required bool canManage,
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.75,
      child: GroupMembersSheet(
        roomId: roomId,
        canManage: canManage,
        onChanged: onChanged,
      ),
    ),
  );
}

class GroupMembersSheet extends ConsumerStatefulWidget {
  const GroupMembersSheet({
    super.key,
    required this.roomId,
    required this.canManage,
    this.onChanged,
  });

  final String roomId;
  final bool canManage;
  final VoidCallback? onChanged;

  @override
  ConsumerState<GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends ConsumerState<GroupMembersSheet> {
  final _search = TextEditingController();
  List<ContactUser>? _members;
  Object? _error;
  bool _picking = false;
  bool _busy = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.roomId);
      if (!mounted) return;
      setState(() => _members = members);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _add(ContactUser user) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .addRoomMember(roomId: widget.roomId, userId: user.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _picking = false;
        _search.clear();
      });
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(ContactUser user) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Xóa thành viên?',
      message: 'Xóa ${user.name} khỏi nhóm?',
    );
    if (!ok || !mounted || _busy) return;

    setState(() => _busy = true);
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .removeRoomMember(roomId: widget.roomId, userId: user.id);
      if (!mounted) return;
      setState(() => _members = members);
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionStorageProvider).user?.id ?? '';
    return Column(
      children: [
        ListTile(
          title: Text(_picking ? 'Thêm thành viên' : 'Thành viên'),
          leading: _picking
              ? IconButton(
                  tooltip: 'Quay lại',
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _picking = false;
                            _search.clear();
                          }),
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_picking && widget.canManage)
                IconButton(
                  tooltip: 'Thêm thành viên',
                  onPressed: _busy ? null : () => setState(() => _picking = true),
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _picking ? _buildPicker() : _buildList(myId)),
      ],
    );
  }

  Widget _buildList(String myId) {
    if (_error != null && _members == null) {
      return ErrorView(message: _error.toString(), onRetry: _load);
    }
    final members = _members;
    if (members == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (members.isEmpty) {
      return const Center(child: Text('Chưa có thành viên'));
    }
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = members[index];
        final canRemove = widget.canManage && user.id != myId && !_busy;
        return ListTile(
          leading: ChatMessageAvatar(
            displayName: user.name,
            avatarUrl: user.avatarUrl,
            radius: 20,
          ),
          title: Text(user.name),
          subtitle: Text(
            [
              if (user.id == myId) 'Bạn',
              if (user.email.isNotEmpty) user.email,
            ].join(' · '),
          ),
          trailing: canRemove
              ? IconButton(
                  tooltip: 'Xóa khỏi nhóm',
                  onPressed: () => _remove(user),
                  icon: const Icon(Icons.remove_circle_outline),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPicker() {
    final usersAsync = ref.watch(contactSearchProvider(_query));
    final memberIds = {for (final m in _members ?? const <ContactUser>[]) m.id};
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            enabled: !_busy,
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên hoặc email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(contactSearchProvider(_query)),
            ),
            data: (users) {
              final candidates =
                  users.where((u) => !memberIds.contains(u.id)).toList();
              if (candidates.isEmpty) {
                return const Center(child: Text('Không còn người để thêm'));
              }
              return ListView.separated(
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = candidates[index];
                  return ListTile(
                    leading: ChatMessageAvatar(
                      displayName: user.name,
                      avatarUrl: user.avatarUrl,
                      radius: 20,
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.email} · ${user.team}'),
                    enabled: !_busy,
                    onTap: () => _add(user),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
