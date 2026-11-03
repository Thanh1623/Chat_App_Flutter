import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:flutter/material.dart';

Future<CreateTaskDraft?> showCreateTaskSheet({
  required BuildContext context,
  required List<ContactUser> members,
  String? suggestedAssigneeId,
  CreateTaskDraft? editing,
}) {
  return showModalBottomSheet<CreateTaskDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: CreateTaskSheet(
        members: members,
        suggestedAssigneeId: suggestedAssigneeId,
        editing: editing,
      ),
    ),
  );
}

class CreateTaskDraft {
  const CreateTaskDraft({
    required this.title,
    required this.assigneeId,
    this.notes,
    this.dueAt,
  });

  final String title;
  final String assigneeId;
  final String? notes;
  final DateTime? dueAt;
}

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.members,
    this.suggestedAssigneeId,
    this.editing,
  });

  final List<ContactUser> members;
  final String? suggestedAssigneeId;

  /// Có giá trị → chế độ sửa việc (không đổi người nhận).
  final CreateTaskDraft? editing;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  late String? _assigneeId;
  DateTime? _dueAt;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _title.text = editing.title;
      _notes.text = editing.notes ?? '';
      _dueAt = editing.dueAt;
      _assigneeId = editing.assigneeId;
      return;
    }
    final suggested = widget.suggestedAssigneeId?.trim() ?? '';
    final ids = widget.members.map((m) => m.id).toSet();
    if (suggested.isNotEmpty && ids.contains(suggested)) {
      _assigneeId = suggested;
    } else if (widget.members.length == 1) {
      _assigneeId = widget.members.first.id;
    } else {
      _assigneeId = null;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final assignee = _assigneeId?.trim() ?? '';
    if (title.isEmpty || assignee.isEmpty) return;
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      CreateTaskDraft(
        title: title,
        assigneeId: assignee,
        notes: notes.isEmpty ? null : notes,
        dueAt: _dueAt,
      ),
    );
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final base = _dueAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _dueText(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _title.text.trim().isNotEmpty && (_assigneeId ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
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
          const SizedBox(height: 16),
          Text(
            _isEdit ? 'Sửa việc' : 'Giao việc',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
              border: OutlineInputBorder(),
            ),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Giao cho',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final m in widget.members)
                  DropdownMenuItem(value: m.id, child: Text(m.name)),
              ],
              onChanged: (id) => setState(() => _assigneeId = id),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Hôm nay 18:00'),
                selected: _isToday18(),
                onSelected: (_) => setState(() => _dueAt = _todayAt(18)),
              ),
              ChoiceChip(
                label: const Text('Ngày mai 09:00'),
                selected: _isTomorrow9(),
                onSelected: (_) => setState(() => _dueAt = _tomorrowAt(9)),
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 16),
                label: Text(
                  _dueAt != null && !_isToday18() && !_isTomorrow9()
                      ? _dueText(_dueAt!)
                      : 'Chọn ngày giờ…',
                ),
                onPressed: _pickDue,
              ),
              ChoiceChip(
                label: const Text('Không hạn'),
                selected: _dueAt == null,
                onSelected: (_) => setState(() => _dueAt = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Text(_isEdit ? 'Lưu' : 'Giao'),
          ),
        ],
      ),
    );
  }

  DateTime _todayAt(int hour) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, hour);
  }

  DateTime _tomorrowAt(int hour) {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day, hour);
  }

  bool _isToday18() {
    final d = _dueAt;
    if (d == null) return false;
    final t = _todayAt(18);
    return d.year == t.year &&
        d.month == t.month &&
        d.day == t.day &&
        d.hour == 18;
  }

  bool _isTomorrow9() {
    final d = _dueAt;
    if (d == null) return false;
    final t = _tomorrowAt(9);
    return d.year == t.year &&
        d.month == t.month &&
        d.day == t.day &&
        d.hour == 9;
  }
}
