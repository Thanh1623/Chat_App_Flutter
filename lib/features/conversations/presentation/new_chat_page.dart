import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final _search = TextEditingController();
  final _groupName = TextEditingController();
  bool _groupMode = false;
  final _selected = <String>{};
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _openDirect(ContactUser user) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(conversationsRepositoryProvider);
      final conv = await repo.openDirect(user.id);
      if (!mounted) return;
      ref.read(conversationsInboxProvider.notifier).refreshInbox();
      context.push(
        AppRoutes.chatPath(conv.id),
        extra: ChatRouteArgs(title: conv.title),
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

  Future<void> _createGroup() async {
    if (_busy || _selected.isEmpty) return;
    final name = _groupName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên nhóm')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(conversationsRepositoryProvider);
      final conv = await repo.createGroup(
        name: name,
        memberIds: _selected.toList(),
      );
      if (!mounted) return;
      ref.read(conversationsInboxProvider.notifier).refreshInbox();
      context.push(
        AppRoutes.chatPath(conv.id),
        extra: ChatRouteArgs(title: conv.title, canDelete: conv.canDelete),
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

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(contactSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupMode ? 'Tạo nhóm' : 'Chat cá nhân'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _groupMode = !_groupMode;
                      _selected.clear();
                    }),
            child: Text(_groupMode ? 'Cá nhân' : 'Nhóm'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_groupMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _groupName,
                decoration: const InputDecoration(
                  labelText: 'Tên nhóm',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_groupMode && _selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Đã chọn ${_selected.length} thành viên'),
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
                    if (_groupMode) {
                      final checked = _selected.contains(user.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: _busy
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(user.id);
                                  } else {
                                    _selected.remove(user.id);
                                  }
                                });
                              },
                        title: Text(user.name),
                        subtitle: Text('${user.email} · ${user.team}'),
                        secondary: CircleAvatar(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                      );
                    }
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text('${user.email} · ${user.team}'),
                      onTap: _busy ? null : () => _openDirect(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _groupMode && _selected.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'fab_new_chat_group',
              onPressed: _busy ? null : _createGroup,
              child: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            )
          : null,
    );
  }
}
