import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/conversations/presentation/widgets/conversation_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendCount = ref.watch(contactSearchProvider('')).maybeWhen(
          data: (users) => users.length,
          orElse: () => null,
        );
    final groupCount = ref.watch(conversationsProvider).maybeWhen(
          data: (items) =>
              items.where((c) => c.type == ConversationType.group).length,
          orElse: () => null,
        );
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: primary,
          indicatorColor: primary,
          tabs: [
            Tab(text: _tabLabel('Bạn bè', friendCount)),
            Tab(text: _tabLabel('Nhóm', groupCount)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: _tabs.index == 0
                    ? 'Tìm bạn bè'
                    : 'Tìm nhóm',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FriendsTab(query: _query),
                _GroupsTab(query: _query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _tabLabel(String label, int? count) =>
    count == null ? label : '$label ($count)';

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(contactSearchProvider(query));
    return asyncUsers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(contactSearchProvider(query)),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Không tìm thấy người dùng'));
        }
        if (query.isNotEmpty) {
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _FriendTile(user: users[index]),
          );
        }
        final sections = _groupByLetter(users);
        return ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    section.letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ...section.users.map((user) => _FriendTile(user: user)),
              ],
            );
          },
        );
      },
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConversations = ref.watch(conversationsProvider);
    return asyncConversations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.read(conversationsInboxProvider.notifier).refreshInbox(),
      ),
      data: (items) {
        final q = query.toLowerCase();
        final groups = items
            .where((c) => c.type == ConversationType.group)
            .where(
              (c) => q.isEmpty || c.title.toLowerCase().contains(q),
            )
            .toList();
        return ListView(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.group_add_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Tạo nhóm mới'),
              subtitle: const Text('Cùng trò chuyện với đồng nghiệp'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.newChat),
            ),
            const Divider(height: 1),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text('Chưa tham gia nhóm nào'),
                  ],
                ),
              )
            else
              ...groups.map((g) => ConversationListTile(conversation: g)),
          ],
        );
      },
    );
  }
}

class _FriendTile extends ConsumerStatefulWidget {
  const _FriendTile({required this.user});

  final ContactUser user;

  @override
  ConsumerState<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends ConsumerState<_FriendTile> {
  bool _busy = false;

  Future<void> _openChat() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final conv = await ref
          .read(conversationsRepositoryProvider)
          .openDirect(widget.user.id);
      if (!mounted) return;
      ref.read(conversationsInboxProvider.notifier).refreshInbox();
      context.push(
        AppRoutes.chatPath(conv.id),
        extra: ChatRouteArgs(
          title: conv.title,
          type: conv.type,
          peerUserId: conv.peerUserId,
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

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final subtitle = user.team.trim().isEmpty
        ? user.email
        : '${_teamLabel(user.team)} · ${user.email}';
    return ListTile(
      leading: ChatMessageAvatar(
        displayName: user.name,
        avatarUrl: user.avatarUrl,
        radius: 22,
      ),
      title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Nhắn tin',
        onPressed: _busy ? null : _openChat,
        icon: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: () => context.push(AppRoutes.userProfilePath(user.id)),
    );
  }
}

class _LetterSection {
  const _LetterSection(this.letter, this.users);
  final String letter;
  final List<ContactUser> users;
}

List<_LetterSection> _groupByLetter(List<ContactUser> users) {
  final map = <String, List<ContactUser>>{};
  for (final user in users) {
    map.putIfAbsent(_letter(user.name), () => []).add(user);
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  return [for (final k in keys) _LetterSection(k, map[k]!)];
}

String _letter(String name) {
  final t = name.trim();
  if (t.isEmpty) return '#';
  return t.substring(0, 1).toUpperCase();
}

String _teamLabel(String team) {
  switch (team.toLowerCase()) {
    case 'sale':
      return 'Team Sale';
    case 'traffic':
      return 'Team Traffic';
    case 'kho':
      return 'Kho';
    default:
      return team;
  }
}
