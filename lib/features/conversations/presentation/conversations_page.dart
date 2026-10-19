import 'dart:async';

import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/conversations/presentation/widgets/conversation_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _scrollController = ScrollController();
  final _search = TextEditingController();
  String _debouncedQuery = '';
  Timer? _debounce;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final text = _search.text.trim();
    if (text.isEmpty) {
      setState(() => _debouncedQuery = '');
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = text);
    });
  }

  void _onScroll() {
    if (_debouncedQuery.isNotEmpty) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;
    ref.read(conversationsInboxProvider.notifier).loadMore();
  }

  Future<void> _refresh() =>
      ref.read(conversationsInboxProvider.notifier).refreshInbox();

  Future<void> _openDirect(ContactUser user) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final conv =
          await ref.read(conversationsRepositoryProvider).openDirect(user.id);
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
      if (mounted) setState(() => _opening = false);
    }
  }

  void _openRoom({
    required String id,
    required String title,
    required ConversationType type,
    String? peerUserId,
    bool canDelete = false,
  }) {
    context.push(
      AppRoutes.chatPath(id),
      extra: ChatRouteArgs(
        title: title,
        canDelete: canDelete,
        type: type,
        peerUserId: peerUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = _debouncedQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tin nhắn, danh bạ...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa',
                    onPressed: () {
                      _debounce?.cancel();
                      _search.clear();
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      body: searching ? _searchBody() : _inboxBody(),
    );
  }

  Widget _searchBody() {
    final async = ref.watch(inboxSearchProvider(_debouncedQuery));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(inboxSearchProvider(_debouncedQuery)),
      ),
      data: (result) {
        if (result.isEmpty) {
          return const Center(child: Text('Không tìm thấy kết quả'));
        }
        return ListView(
          children: [
            if (result.users.isNotEmpty) ...[
              const _SectionLabel('Tài khoản'),
              for (final user in result.users)
                ListTile(
                  leading: ChatMessageAvatar(
                    displayName: user.name,
                    avatarUrl: user.avatarUrl,
                    radius: 22,
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: _opening ? null : () => _openDirect(user),
                ),
            ],
            if (result.rooms.isNotEmpty) ...[
              const _SectionLabel('Nhóm'),
              for (final room in result.rooms)
                ConversationListTile(conversation: room),
            ],
            if (result.messages.isNotEmpty) ...[
              const _SectionLabel('Tin nhắn'),
              for (final message in result.messages)
                ListTile(
                  leading: ChatMessageAvatar(
                    displayName: message.roomTitle,
                    avatarUrl: message.roomAvatarUrl,
                    radius: 22,
                  ),
                  title: Text(
                    message.roomTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${message.authorName}: ${message.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _openRoom(
                    id: message.roomId,
                    title: message.roomTitle,
                    type: message.isGroup
                        ? ConversationType.group
                        : ConversationType.direct,
                    peerUserId: message.peerUserId,
                    canDelete: message.canDelete,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _inboxBody() {
    final asyncInbox = ref.watch(conversationsInboxProvider);
    return asyncInbox.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: _refresh,
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 56,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có cuộc trò chuyện',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bắt đầu chat mới từ tab Danh bạ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final itemCount =
            state.items.length + (state.loadingMore || state.hasMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (context, index) {
              if (index >= state.items.length - 1) {
                return const SizedBox.shrink();
              }
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: state.loadingMore
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }
              return ConversationListTile(conversation: state.items[index]);
            },
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
