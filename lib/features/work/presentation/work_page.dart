import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:chat_app/features/work/presentation/providers/work_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkPage extends ConsumerWidget {
  const WorkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTasksProvider);
    final myId = ref.watch(sessionStorageProvider).user?.id;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc của tôi'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(myTasksProvider.notifier).refresh(),
        ),
        data: (tasks) {
          final open = tasks.where((t) => !t.isDone).toList()..sort(_compareOpen);
          if (open.isEmpty) {
            return RefreshIndicator(
              color: primary,
              onRefresh: () => ref.read(myTasksProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Chưa có việc được giao hoặc bạn đã giao.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: primary,
            onRefresh: () => ref.read(myTasksProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: open.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = open[index];
                return ListTile(
                  leading: Checkbox(
                    value: false,
                    onChanged: (_) =>
                        ref.read(myTasksProvider.notifier).toggleDone(task),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    [
                      _roleLabel(task, myId),
                      if (task.roomName.isNotEmpty) task.roomName,
                      _dueLabel(task),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _openChat(context, task),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static int _compareOpen(WorkTask a, WorkTask b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    if (a.isDueToday != b.isDueToday) return a.isDueToday ? -1 : 1;
    final ad = a.dueAt;
    final bd = b.dueAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  static String _roleLabel(WorkTask task, String? myId) {
    if (myId != null && myId == task.assigneeId) {
      return task.creatorName.isEmpty
          ? 'Được giao'
          : 'Được ${task.creatorName} giao';
    }
    if (myId != null && myId == task.creatorId) {
      return task.assigneeName.isEmpty
          ? 'Tôi giao'
          : 'Tôi giao ${task.assigneeName}';
    }
    return '';
  }

  static String _dueLabel(WorkTask task) {
    if (task.dueAt == null) return 'Không hạn';
    if (task.isOverdue) return 'Quá hạn';
    if (task.isDueToday) return 'Hôm nay';
    final d = task.dueAt!.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  static void _openChat(BuildContext context, WorkTask task) {
    if (task.roomId.isEmpty) return;
    var path = AppRoutes.chatPath(task.roomId);
    final messageId = task.messageId?.trim() ?? '';
    if (messageId.isNotEmpty) {
      path = '$path?m=$messageId';
    }
    context.push(path, extra: task.roomName);
  }
}
