import 'dart:async';

import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/work/data/providers/work_repository_provider.dart';
import 'package:chat_app/features/work/domain/entities/task_notice.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myTasksProvider =
    AsyncNotifierProvider<MyTasksNotifier, List<WorkTask>>(MyTasksNotifier.new);

int workBadgeCount(List<WorkTask> tasks) {
  return tasks.where((t) => !t.isDone && (t.isOverdue || t.isDueToday)).length;
}

final workBadgeCountProvider = Provider<int>((ref) {
  return ref.watch(myTasksProvider).maybeWhen(
        data: workBadgeCount,
        orElse: () => 0,
      );
});

final taskNoticeProvider = StateProvider<TaskNotice?>((ref) => null);

/// Socket `task` → refresh list + snackbar. Join `user:{id}` lúc connect.
final workRealtimeSyncProvider = Provider<void>((ref) {
  final socket = ref.read(chatSocketClientProvider);
  final sub = socket.tasks.listen((json) {
    unawaited(ref.read(myTasksProvider.notifier).refresh());
    unawaited(ref.read(conversationsInboxProvider.notifier).refreshInbox());
    ref.read(taskNoticeProvider.notifier).state = TaskNotice.fromJson(json);
  });
  ref.onDispose(sub.cancel);
});

class MyTasksNotifier extends AsyncNotifier<List<WorkTask>> {
  @override
  Future<List<WorkTask>> build() {
    return _load();
  }

  Future<List<WorkTask>> _load() {
    return ref.read(workRepositoryProvider).listMine();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleDone(WorkTask task) async {
    final next = task.isDone ? 'open' : 'done';
    try {
      await ref.read(workRepositoryProvider).updateTask(
            taskId: task.id,
            status: next,
          );
      await refresh();
    } on Failure catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
