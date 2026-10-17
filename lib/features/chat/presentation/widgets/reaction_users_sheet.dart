import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:flutter/material.dart';

Future<void> showReactionUsersSheet({
  required BuildContext context,
  required ChatMessage message,
  required String initialEmoji,
  required void Function(String userId) onOpenUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReactionUsersSheet(
      message: message,
      initialEmoji: initialEmoji,
      onOpenUser: onOpenUser,
    ),
  );
}

class _ReactionUsersSheet extends StatefulWidget {
  const _ReactionUsersSheet({
    required this.message,
    required this.initialEmoji,
    required this.onOpenUser,
  });

  final ChatMessage message;
  final String initialEmoji;
  final void Function(String userId) onOpenUser;

  @override
  State<_ReactionUsersSheet> createState() => _ReactionUsersSheetState();
}

class _ReactionUsersSheetState extends State<_ReactionUsersSheet> {
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _emoji = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reactions = widget.message.reactions;
    final selected = reactions.where((r) => r.emoji == _emoji);
    final current = selected.isEmpty ? null : selected.first;
    final users = current?.users ?? const <ReactionUser>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(20),
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
                    'Đã thả react',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final reaction in reactions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${reaction.emoji} ${reaction.count}',
                            ),
                            selected: reaction.emoji == _emoji,
                            onSelected: (_) =>
                                setState(() => _emoji = reaction.emoji),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                  child: users.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Chưa có ai thả react này'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ChatMessageAvatar(
                                displayName: user.name,
                                avatarUrl: user.avatarUrl,
                              ),
                              title: Text(user.name),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onOpenUser(user.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
