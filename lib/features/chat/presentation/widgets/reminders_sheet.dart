import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/features/chat/domain/entities/room_reminder.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/chat/presentation/widgets/create_reminder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRoomRemindersSheet({
  required BuildContext context,
  required String roomId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.62,
      child: RoomRemindersSheet(roomId: roomId),
    ),
  );
}

class RoomRemindersSheet extends ConsumerWidget {
  const RoomRemindersSheet({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatControllerProvider(roomId));
    final myId = ref.watch(sessionStorageProvider).user?.id;
    final items = chat.reminders;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 36,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nhắc hẹn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Chưa có nhắc hẹn nào'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = items[index];
                      final mine = myId != null && myId == r.creatorId;
                      return ListTile(
                        leading: const Icon(Icons.alarm_outlined),
                        title: Text(r.title),
                        subtitle: Text(
                          [
                            r.remindAtLabel,
                            if (r.isRepeating) r.repeatLabel,
                          ].join(' · '),
                        ),
                        trailing: mine
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Sửa',
                                    onPressed: () => _edit(context, ref, r),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa',
                                    onPressed: () => _delete(context, ref, r),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showCreateReminderSheet(context: context);
    if (draft == null || !context.mounted) return;
    await ref
        .read(chatControllerProvider(roomId).notifier)
        .createReminder(
          title: draft.title,
          remindAt: draft.remindAt,
          repeat: draft.repeat,
        );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RoomReminder reminder,
  ) async {
    final draft = await showCreateReminderSheet(
      context: context,
      editing: reminder,
    );
    if (draft == null || !context.mounted) return;
    await ref
        .read(chatControllerProvider(roomId).notifier)
        .updateReminder(
          reminderId: reminder.id,
          title: draft.title,
          remindAt: draft.remindAt,
          repeat: draft.repeat,
        );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RoomReminder reminder,
  ) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Xóa nhắc hẹn?',
      message: 'Bạn có chắc muốn xóa “${reminder.title}”?',
      confirmLabel: 'Xóa',
    );
    if (!ok || !context.mounted) return;
    await ref
        .read(chatControllerProvider(roomId).notifier)
        .deleteReminder(reminder.id);
  }
}
