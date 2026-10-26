class WorkTask {
  const WorkTask({
    required this.id,
    required this.title,
    required this.status,
    required this.roomId,
    required this.creatorId,
    required this.assigneeId,
    this.notes = '',
    this.dueAt,
    this.roomName = '',
    this.messageId,
    this.creatorName = '',
    this.assigneeName = '',
  });

  final String id;
  final String title;
  final String notes;
  final String status;
  final DateTime? dueAt;
  final String roomId;
  final String roomName;
  final String? messageId;
  final String creatorId;
  final String assigneeId;
  final String creatorName;
  final String assigneeName;

  bool get isDone => status == 'done';

  bool get isOverdue {
    if (isDone || dueAt == null) return false;
    return dueAt!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (isDone || dueAt == null) return false;
    final due = dueAt!.toLocal();
    final now = DateTime.now();
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }
}
