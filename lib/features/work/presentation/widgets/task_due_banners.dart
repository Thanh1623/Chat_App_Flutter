import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:chat_app/features/work/presentation/providers/task_due_banner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khung bọc toàn app: banner việc sắp hết hạn ghim phía trên **mọi màn hình**.
/// Không tự tắt — chỉ biến mất khi bấm X (hoặc xong việc / đổi hạn).
///
/// Cấu trúc cây luôn cố định (Column + Expanded) nên Navigator bên dưới
/// không bị dựng lại khi banner xuất hiện hay biến mất.
class TaskDueBannerFrame extends ConsumerWidget {
  const TaskDueBannerFrame({
    super.key,
    required this.child,
    required this.onOpenTask,
  });

  final Widget child;
  final void Function(WorkTask task) onOpenTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(dueSoonTasksProvider);
    return Column(
      children: [
        if (tasks.isNotEmpty)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                for (final t in tasks)
                  _BannerCard(
                    key: ValueKey(taskBannerKey(t)),
                    task: t,
                    onOpen: () => onOpenTask(t),
                    onClose: () => ref
                        .read(dismissedTaskBannersProvider.notifier)
                        .update((s) => {...s, taskBannerKey(t)}),
                  ),
              ],
            ),
          ),
        Expanded(
          // Banner đã chiếm vùng status bar → trang bên dưới bỏ padding trên.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: tasks.isNotEmpty,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onClose,
  });

  final WorkTask task;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  String _status() {
    final left = task.dueAt!.difference(DateTime.now());
    if (left.isNegative) return 'Đã quá hạn ${_span(-left)}';
    if (left.inSeconds < 60) return 'Hết hạn trong dưới 1 phút';
    return 'Còn ${_span(left)} là hết hạn';
  }

  static String _span(Duration d) {
    final m = d.inMinutes;
    if (m < 1) return 'dưới 1 phút';
    if (m < 60) return '$m phút';
    return '${d.inHours} giờ ${m % 60} phút';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueAt!.isBefore(DateTime.now());
    final color = overdue ? const Color(0xFFD32F2F) : const Color(0xFFE65100);
    final bg = overdue ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                overdue ? Icons.alarm_on_outlined : Icons.alarm_outlined,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      _status(),
                      style: TextStyle(fontSize: 12.5, color: color),
                    ),
                  ],
                ),
              ),
              // Không dùng `tooltip`: khung này nằm trên Navigator nên không có
              // Overlay, Tooltip sẽ ném "No Overlay widget found".
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: color,
                  semanticLabel: 'Đóng cảnh báo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
