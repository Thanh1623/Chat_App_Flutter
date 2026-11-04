import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:chat_app/features/work/presentation/providers/work_tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hiện banner khi còn ≤ [taskBannerLead] tới hạn, và còn giữ ≤ [taskBannerOverdueKeep]
/// sau khi quá hạn (việc quá hạn lâu hơn thì không nhắc nữa).
const taskBannerLead = Duration(minutes: 30);
const taskBannerOverdueKeep = Duration(hours: 1);

/// Khóa việc đã bị người dùng bấm X (theo id + hạn → đổi hạn thì hiện lại).
final dismissedTaskBannersProvider = StateProvider<Set<String>>((ref) => {});

String taskBannerKey(WorkTask t) =>
    '${t.id}:${t.dueAt?.millisecondsSinceEpoch ?? 0}';

/// Tick mỗi 30 giây để banner tự xuất hiện khi việc chạm mốc.
final _clockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

/// Việc được giao cho mình, chưa xong, sắp/vừa hết hạn và chưa bị đóng banner.
final dueSoonTasksProvider = Provider.autoDispose<List<WorkTask>>((ref) {
  // Chưa đăng nhập thì không tải việc (tránh gọi API 401 ở màn đăng nhập).
  final myId = ref.watch(authControllerProvider).user?.id;
  if (myId == null || myId.isEmpty) return const [];
  final tasks = ref.watch(myTasksProvider).valueOrNull;
  final dismissed = ref.watch(dismissedTaskBannersProvider);
  final now = ref.watch(_clockProvider).valueOrNull ?? DateTime.now();
  if (tasks == null) return const [];

  final result = tasks.where((t) {
    final due = t.dueAt;
    if (t.isDone || due == null || t.assigneeId != myId) return false;
    if (dismissed.contains(taskBannerKey(t))) return false;
    final left = due.difference(now);
    return left <= taskBannerLead && -left <= taskBannerOverdueKeep;
  }).toList()
    ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  return result;
});
