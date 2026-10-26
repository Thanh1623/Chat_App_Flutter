import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter/material.dart';

class WorkTaskCard extends StatelessWidget {
  const WorkTaskCard({
    super.key,
    required this.message,
    required this.myId,
    this.onToggle,
  });

  final ChatMessage message;
  final String? myId;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final task = message.task;
    if (task == null) return const SizedBox.shrink();
    final done = task.isDone;
    final canToggle = myId != null &&
        (myId == task.assigneeId || myId == task.creatorId);
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              done ? 'XONG' : 'VIỆC',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: done ? Colors.green : primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (task.assigneeName.isNotEmpty) 'Giao ${task.assigneeName}',
                if (task.dueAt != null) _due(task.dueAt!),
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (canToggle) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onToggle,
                  child: Text(done ? 'Mở lại' : 'Đánh dấu xong'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _due(DateTime due) {
    final d = due.toLocal();
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return 'Hạn ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hm';
  }
}
