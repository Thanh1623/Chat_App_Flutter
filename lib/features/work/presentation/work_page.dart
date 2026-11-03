import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/chat/presentation/widgets/create_task_sheet.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công việc'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Được giao'),
              Tab(text: 'Đã giao'),
              Tab(text: 'Lịch'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _createTask(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Giao việc'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(myTasksProvider.notifier).refresh(),
          ),
          data: (tasks) {
            final assigned =
                tasks.where((t) => t.assigneeId == myId).toList();
            final created = tasks.where((t) => t.creatorId == myId).toList();
            return TabBarView(
              children: [
                _TaskListTab(
                  tasks: assigned,
                  myId: myId,
                  emptyText: 'Chưa có việc nào được giao cho bạn.',
                ),
                _TaskListTab(
                  tasks: created,
                  myId: myId,
                  emptyText: 'Bạn chưa giao việc nào.',
                ),
                _CalendarTab(tasks: tasks, myId: myId),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- tạo việc

Future<void> _createTask(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final inbox = ref.read(conversationsInboxProvider).valueOrNull;
    final groups = (inbox?.items ?? const <Conversation>[])
        .where((c) => c.type == ConversationType.group)
        .toList();
    final target = await showModalBottomSheet<Object>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => _TargetPickerSheet(groups: groups),
    );
    if (target == null || !context.mounted) return;

    final repo = ref.read(conversationsRepositoryProvider);
    final String roomId;
    final String? suggested;
    if (target == _selfTarget) {
      // Tự giao: phòng "Cloud của tôi" chỉ có mình bạn.
      final cloud = await repo.openCloud();
      roomId = cloud.id;
      suggested = ref.read(sessionStorageProvider).user?.id;
    } else if (target is ContactUser) {
      // Cá nhân: mở/tạo chat 1-1 làm nơi chứa việc.
      final direct = await repo.openDirect(target.id);
      roomId = direct.id;
      suggested = target.id;
    } else {
      roomId = (target as Conversation).id;
      suggested = null;
    }
    final members = await repo.fetchRoomMembers(roomId);
    if (!context.mounted) return;
    final draft = await showCreateTaskSheet(
      context: context,
      members: members,
      suggestedAssigneeId: suggested,
    );
    if (draft == null) return;
    await ref.read(myTasksProvider.notifier).create(
          roomId: roomId,
          title: draft.title,
          assigneeId: draft.assigneeId,
          notes: draft.notes,
          dueAt: draft.dueAt,
        );
    messenger.showSnackBar(const SnackBar(content: Text('Đã giao việc')));
  } on Failure catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

const _selfTarget = 'self';

/// Chọn đối tượng giao việc: cá nhân (trả [ContactUser]) hoặc nhóm (trả [Conversation]).
class _TargetPickerSheet extends ConsumerStatefulWidget {
  const _TargetPickerSheet({required this.groups});

  final List<Conversation> groups;

  @override
  ConsumerState<_TargetPickerSheet> createState() => _TargetPickerSheetState();
}

class _TargetPickerSheetState extends ConsumerState<_TargetPickerSheet> {
  String _query = '';
  String _groupQuery = '';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Giao việc cho',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person_outline), text: 'Cá nhân'),
                Tab(icon: Icon(Icons.groups_outlined), text: 'Nhóm'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_peopleTab(context), _groupsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _peopleTab(BuildContext context) {
    final async = ref.watch(contactSearchProvider(_query));
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person_pin_circle_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: const Text('Chính tôi'),
          subtitle: const Text('Tự giao việc cho bản thân'),
          onTap: () => Navigator.of(context).pop(_selfTarget),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm theo tên hoặc email',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (users) => users.isEmpty
                ? const Center(child: Text('Không tìm thấy người dùng'))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return ListTile(
                        leading: ChatMessageAvatar(
                          displayName: u.name,
                          avatarUrl: u.avatarUrl,
                          radius: 20,
                        ),
                        title: Text(u.name),
                        subtitle: Text(
                          u.orgLabel.isEmpty ? u.email : u.orgLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(u),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _groupsTab() {
    if (widget.groups.isEmpty) {
      return const Center(child: Text('Bạn chưa tham gia nhóm nào'));
    }
    final q = _groupQuery.toLowerCase();
    final groups = q.isEmpty
        ? widget.groups
        : widget.groups
              .where((g) => g.title.toLowerCase().contains(q))
              .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _groupQuery = v.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm nhóm',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('Không tìm thấy nhóm'))
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return ListTile(
                      leading: ChatMessageAvatar(
                        displayName: g.title,
                        avatarUrl: g.avatarUrl,
                        radius: 20,
                      ),
                      title: Text(
                        g.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Chọn người nhận trong nhóm'),
                      onTap: () => Navigator.of(context).pop(g),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- danh sách việc

class _TaskListTab extends ConsumerWidget {
  const _TaskListTab({
    required this.tasks,
    required this.myId,
    required this.emptyText,
  });

  final List<WorkTask> tasks;
  final String? myId;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = tasks.where((t) => !t.isDone).toList()..sort(_compareOpen);
    final done = tasks.where((t) => t.isDone).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      color: primary,
      onRefresh: () => ref.read(myTasksProvider.notifier).refresh(),
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    emptyText,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (open.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Không còn việc đang mở 🎉',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                for (final t in open) _TaskTile(task: t, myId: myId),
                if (done.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Đã hoàn thành (${done.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  for (final t in done) _TaskTile(task: t, myId: myId),
                ],
              ],
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
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.myId});

  final WorkTask task;
  final String? myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = task.isOverdue;
    return ListTile(
      leading: Checkbox(
        value: task.isDone,
        onChanged: (_) => ref.read(myTasksProvider.notifier).toggleDone(task),
      ),
      title: Text(
        task.title,
        style: task.isDone
            ? const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.black45,
              )
            : null,
      ),
      subtitle: Text(
        [
          _roleLabel(task, myId),
          if (task.roomName.isNotEmpty) task.roomName,
          _dueLabel(task),
        ].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: overdue ? const TextStyle(color: Colors.redAccent) : null,
      ),
      onTap: () => showTaskDetail(context, ref, task, myId),
    );
  }
}

String _roleLabel(WorkTask task, String? myId) {
  if (myId != null && myId == task.assigneeId && myId == task.creatorId) {
    return 'Tự giao';
  }
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

String _two(int v) => v.toString().padLeft(2, '0');

String _dueLabel(WorkTask task) {
  if (task.dueAt == null) return 'Không hạn';
  final d = task.dueAt!.toLocal();
  final hm = '${_two(d.hour)}:${_two(d.minute)}';
  if (task.isOverdue) return 'Quá hạn · ${_two(d.day)}/${_two(d.month)}';
  if (task.isDueToday) return 'Hôm nay $hm';
  return '${_two(d.day)}/${_two(d.month)} $hm';
}

// -------------------------------------------------------- chi tiết/sửa/xóa

Future<void> showTaskDetail(
  BuildContext context,
  WidgetRef ref,
  WorkTask task,
  String? myId,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => _TaskDetailSheet(task: task, myId: myId, parentRef: ref),
  );
}

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.task,
    required this.myId,
    required this.parentRef,
  });

  final WorkTask task;
  final String? myId;
  final WidgetRef parentRef;

  bool get _isCreator => myId != null && myId == task.creatorId;

  Future<void> _edit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final navContext = parentRef.context;
    final draft = await showCreateTaskSheet(
      context: navContext,
      members: const [],
      editing: CreateTaskDraft(
        title: task.title,
        assigneeId: task.assigneeId,
        notes: task.notes,
        dueAt: task.dueAt?.toLocal(),
      ),
    );
    if (draft == null) return;
    try {
      await parentRef.read(myTasksProvider.notifier).edit(
            taskId: task.id,
            title: draft.title,
            notes: draft.notes ?? '',
            dueAt: draft.dueAt,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật việc')));
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa việc?'),
        content: Text('"${task.title}" sẽ bị xóa với cả người nhận.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).pop();
    try {
      await parentRef.read(myTasksProvider.notifier).remove(task.id);
      messenger.showSnackBar(const SnackBar(content: Text('Đã xóa việc')));
    } on Failure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).pop();
    if (task.roomId.isEmpty) return;
    var path = AppRoutes.chatPath(task.roomId);
    final messageId = task.messageId?.trim() ?? '';
    if (messageId.isNotEmpty) path = '$path?m=$messageId';
    GoRouter.of(parentRef.context).push(path, extra: task.roomName);
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.flag_outlined,
            text: task.isDone ? 'Đã hoàn thành' : 'Đang mở',
          ),
          _DetailRow(icon: Icons.event_outlined, text: _dueLabel(task)),
          if (task.creatorName.isNotEmpty)
            _DetailRow(
              icon: Icons.person_outline,
              text: 'Người giao: ${task.creatorName}',
            ),
          if (task.assigneeName.isNotEmpty)
            _DetailRow(
              icon: Icons.assignment_ind_outlined,
              text: 'Người nhận: ${task.assigneeName}',
            ),
          if (task.roomName.isNotEmpty)
            _DetailRow(icon: Icons.forum_outlined, text: task.roomName),
          if (task.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task.notes, style: TextStyle(color: outline)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  parentRef.read(myTasksProvider.notifier).toggleDone(task);
                },
                icon: Icon(
                  task.isDone ? Icons.replay : Icons.check_circle_outline,
                ),
                label: Text(task.isDone ? 'Mở lại' : 'Hoàn thành'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Mở chat'),
              ),
              if (_isCreator)
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa'),
                ),
              if (_isCreator)
                OutlinedButton.icon(
                  onPressed: () => _delete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- lịch

class _CalendarTab extends ConsumerStatefulWidget {
  const _CalendarTab({required this.tasks, required this.myId});

  final List<WorkTask> tasks;
  final String? myId;

  @override
  ConsumerState<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<_CalendarTab> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<WorkTask> _tasksOn(DateTime day) {
    return widget.tasks.where((t) {
      final d = t.dueAt?.toLocal();
      return d != null && _sameDay(d, day);
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Thứ Hai là cột đầu: DateTime.monday == 1.
    final leading = first.weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = DateTime.now();
    final selectedTasks = _tasksOn(_selected);

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tháng ${_month.month}/${_month.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final d in const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                      index: r * 7 + c - leading + 1,
                      daysInMonth: daysInMonth,
                      today: today,
                      primary: primary,
                    ),
                  ),
              ],
            ),
          ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Ngày ${_two(_selected.day)}/${_two(_selected.month)}/${_selected.year}'
            ' · ${selectedTasks.length} việc',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (selectedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Không có việc nào đến hạn trong ngày này.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        for (final t in selectedTasks) _TaskTile(task: t, myId: widget.myId),
      ],
    );
  }

  Widget _dayCell({
    required int index,
    required int daysInMonth,
    required DateTime today,
    required Color primary,
  }) {
    if (index < 1 || index > daysInMonth) {
      return const SizedBox(height: 48);
    }
    final day = DateTime(_month.year, _month.month, index);
    final isSelected = _sameDay(day, _selected);
    final isToday = _sameDay(day, today);
    final tasks = _tasksOn(day);
    final hasOpen = tasks.any((t) => !t.isDone);
    final hasOverdue = tasks.any((t) => t.isOverdue);
    final dotColor = hasOverdue
        ? Colors.redAccent
        : (hasOpen ? primary : Colors.green);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selected = day),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? primary : null,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$index',
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
            const SizedBox(height: 3),
            if (tasks.isNotEmpty)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
