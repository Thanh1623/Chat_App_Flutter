import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _search = TextEditingController();
  final _groupName = TextEditingController();
  final _selected = <String, ContactUser>{};
  String _query = '';
  bool _busy = false;

  bool get _canCreate =>
      !_busy &&
      _groupName.text.trim().isNotEmpty &&
      _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text));
    _groupName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_canCreate) return;
    setState(() => _busy = true);
    try {
      final conv = await ref.read(conversationsRepositoryProvider).createGroup(
            name: _groupName.text.trim(),
            memberIds: _selected.keys.toList(),
          );
      if (!mounted) return;
      ref.read(conversationsInboxProvider.notifier).refreshInbox();
      context.pushReplacement(
        AppRoutes.chatPath(conv.id),
        extra: ChatRouteArgs(
          title: conv.title,
          canDelete: conv.canDelete,
          type: conv.type,
        ),
      );
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

  void _toggle(ContactUser user) {
    setState(() {
      if (_selected.containsKey(user.id)) {
        _selected.remove(user.id);
      } else {
        _selected[user.id] = user;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(contactSearchProvider(_query));
    final outline = Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhóm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _groupName,
              textInputAction: TextInputAction.next,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'Ví dụ: Team Sale',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final user in _selected.values)
                      InputChip(
                        avatar: ChatMessageAvatar(
                          displayName: user.name,
                          avatarUrl: user.avatarUrl,
                          radius: 12,
                        ),
                        label: Text(user.name),
                        onDeleted: _busy ? null : () => _toggle(user),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              enabled: !_busy,
              decoration: const InputDecoration(
                hintText: 'Tìm đồng nghiệp để thêm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selected.isEmpty
                    ? 'Chọn ít nhất 1 thành viên'
                    : 'Đã chọn ${_selected.length} thành viên',
                style: TextStyle(fontSize: 13, color: outline),
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
                if (users.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người dùng'));
                }
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final checked = _selected.containsKey(user.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: _busy ? null : (_) => _toggle(user),
                      title: Text(user.name),
                      subtitle: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: ChatMessageAvatar(
                        displayName: user.name,
                        avatarUrl: user.avatarUrl,
                        radius: 20,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _canCreate ? _createGroup : null,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Tạo nhóm'
                            : 'Tạo nhóm (${_selected.length})',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
