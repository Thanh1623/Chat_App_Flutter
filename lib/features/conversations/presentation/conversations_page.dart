import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;
    ref.read(conversationsInboxProvider.notifier).loadMore();
  }

  Future<void> _refresh() =>
      ref.read(conversationsInboxProvider.notifier).refreshInbox();

  @override
  Widget build(BuildContext context) {
    final asyncInbox = ref.watch(conversationsInboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: asyncInbox.when(
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
                              'Bắt đầu chat mới từ nút bút bên dưới',
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_conversations',
        onPressed: () => context.push(AppRoutes.newChat),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
