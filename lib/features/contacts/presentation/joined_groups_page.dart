import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/conversations/presentation/widgets/conversation_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinedGroupsPage extends ConsumerWidget {
  const JoinedGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Danh bạ'),
            Text(
              'Nhóm đã tham gia',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: asyncConversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) {
          final groups =
              items.where((c) => c.type == ConversationType.group).toList();
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa tham gia nhóm nào',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo nhóm mới từ tab Tin nhắn',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                ConversationListTile(conversation: groups[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newChat),
        child: const Icon(Icons.group_add_outlined),
      ),
    );
  }
}
