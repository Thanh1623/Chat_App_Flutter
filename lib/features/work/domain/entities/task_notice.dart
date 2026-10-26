class TaskNotice {
  const TaskNotice({
    required this.action,
    required this.actorId,
    required this.title,
    required this.status,
    required this.assigneeId,
    required this.creatorId,
    this.actorName = '',
    this.actorAvatarUrl = '',
    this.assigneeName = '',
    this.creatorName = '',
    this.roomId = '',
    this.roomName = '',
    this.messageId,
  });

  final String action;
  final String actorId;
  final String actorName;
  final String actorAvatarUrl;
  final String title;
  final String status;
  final String assigneeId;
  final String creatorId;
  final String assigneeName;
  final String creatorName;
  final String roomId;
  final String roomName;
  final String? messageId;

  factory TaskNotice.fromJson(Map<String, dynamic> json) {
    final taskRaw = json['task'];
    final task = taskRaw is Map
        ? Map<String, dynamic>.from(taskRaw)
        : const <String, dynamic>{};
    final creator = task['creator'] is Map
        ? Map<String, dynamic>.from(task['creator'] as Map)
        : const <String, dynamic>{};
    final assignee = task['assignee'] is Map
        ? Map<String, dynamic>.from(task['assignee'] as Map)
        : const <String, dynamic>{};
    final highlight = json['highlightMessageId']?.toString();
    return TaskNotice(
      action: json['action']?.toString() ?? '',
      actorId: json['actorId']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? '',
      actorAvatarUrl: json['actorAvatarUrl']?.toString() ?? '',
      title: task['title']?.toString() ?? '',
      status: task['status']?.toString() ?? '',
      assigneeId: assignee['id']?.toString() ?? '',
      creatorId: creator['id']?.toString() ?? '',
      assigneeName: assignee['name']?.toString() ?? '',
      creatorName: creator['name']?.toString() ?? '',
      roomId: task['roomId']?.toString() ?? '',
      roomName: task['roomName']?.toString() ?? '',
      messageId: (highlight != null && highlight.isNotEmpty)
          ? highlight
          : task['messageId']?.toString(),
    );
  }

  String get preview {
    if (action == 'created') return 'Việc: $title';
    if (status == 'done') return 'Đã xong: $title';
    if (action == 'updated' && status == 'open') return 'Mở lại: $title';
    return 'Cập nhật việc: $title';
  }

  bool shouldShowBanner(String? myId) {
    final me = myId?.trim() ?? '';
    if (me.isEmpty || me == actorId) return false;
    if (action == 'created') return me == assigneeId;
    return me == creatorId || me == assigneeId;
  }
}
