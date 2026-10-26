import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showMessageSeenSheet({
  required BuildContext context,
  required String roomId,
  required ChatMessage message,
  required void Function(String userId) onOpenUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _MessageSeenSheet(
      roomId: roomId,
      message: message,
      onOpenUser: onOpenUser,
    ),
  );
}

class _MessageSeenSheet extends ConsumerStatefulWidget {
  const _MessageSeenSheet({
    required this.roomId,
    required this.message,
    required this.onOpenUser,
  });

  final String roomId;
  final ChatMessage message;
  final void Function(String userId) onOpenUser;

  @override
  ConsumerState<_MessageSeenSheet> createState() => _MessageSeenSheetState();
}

class _MessageSeenSheetState extends ConsumerState<_MessageSeenSheet> {
  List<ContactUser>? _members;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.roomId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chat = ref.watch(chatControllerProvider(widget.roomId));
    final myId = ref.watch(sessionStorageProvider).user?.id;
    final details = _members == null
        ? null
        : splitMessageSeen(
            members: _members!.map(
              (m) => MessageSeenPerson(
                userId: m.id,
                name: m.name,
                avatarUrl: m.avatarUrl,
              ),
            ),
            reads: chat.reads,
            messageId: widget.message.id,
            messageCreatedAt: widget.message.createdAt,
            newestFirstIds: chat.messages.map((m) => m.id).toList(),
            myId: myId,
            senderId: widget.message.userId,
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          child: DefaultTabController(
            length: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chi tiết đã xem',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    labelColor: scheme.primary,
                    tabs: [
                      Tab(text: 'Đã xem (${details?.seen.length ?? 0})'),
                      Tab(text: 'Chưa xem (${details?.unseen.length ?? 0})'),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.42,
                    child: _error != null
                        ? Center(child: Text(_error.toString()))
                        : details == null
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TabBarView(
                            children: [
                              _SeenUserList(
                                people: details.seen,
                                emptyLabel: 'Chưa có ai xem tin này',
                                onOpenUser: _openUser,
                              ),
                              _SeenUserList(
                                people: details.unseen,
                                emptyLabel: 'Mọi người đã xem tin này',
                                onOpenUser: _openUser,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openUser(String userId) {
    Navigator.pop(context);
    widget.onOpenUser(userId);
  }
}

class _SeenUserList extends StatelessWidget {
  const _SeenUserList({
    required this.people,
    required this.emptyLabel,
    required this.onOpenUser,
  });

  final List<MessageSeenPerson> people;
  final String emptyLabel;
  final void Function(String userId) onOpenUser;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: const TextStyle(color: Colors.black45),
        ),
      );
    }
    return ListView.separated(
      itemCount: people.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = people[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ChatMessageAvatar(
            displayName: user.name,
            avatarUrl: user.avatarUrl,
          ),
          title: Text(user.name),
          onTap: () => onOpenUser(user.userId),
        );
      },
    );
  }
}
