import 'package:chat_app/features/chat/domain/entities/room_reminder.dart';
import 'package:flutter/material.dart';

const reminderRepeats = ['none', 'daily', 'weekly'];

Future<CreateReminderDraft?> showCreateReminderSheet({
  required BuildContext context,
  RoomReminder? editing,
}) {
  return showModalBottomSheet<CreateReminderDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: CreateReminderSheet(editing: editing),
    ),
  );
}

class CreateReminderDraft {
  const CreateReminderDraft({
    required this.title,
    required this.remindAt,
    required this.repeat,
  });

  final String title;
  final DateTime remindAt;
  final String repeat;
}

class CreateReminderSheet extends StatefulWidget {
  const CreateReminderSheet({super.key, this.editing});

  final RoomReminder? editing;

  @override
  State<CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<CreateReminderSheet> {
  final _title = TextEditingController();
  late DateTime _remindAt;
  String _repeat = 'none';

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _title.text = editing.title;
      _remindAt = editing.remindAt.toLocal();
      _repeat = editing.repeat;
      return;
    }
    _remindAt = DateTime.now().add(const Duration(minutes: 15));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final t = _title.text.trim();
    return t.isNotEmpty && t.length <= 200 && _remindAt.isAfter(DateTime.now());
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      CreateReminderDraft(
        title: _title.text.trim(),
        remindAt: _remindAt,
        repeat: _repeat,
      ),
    );
  }

  Future<void> _pickAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _remindAt.isAfter(now) ? _remindAt : now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (time == null) return;
    setState(() {
      _remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _repeatLabel(String v) => switch (v) {
    'daily' => 'Hằng ngày',
    'weekly' => 'Hằng tuần',
    _ => 'Không lặp',
  };

  @override
  Widget build(BuildContext context) {
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
            _isEdit ? 'Sửa nhắc hẹn' : 'Tạo nhắc hẹn',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: !_isEdit,
            maxLength: 200,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Nội dung nhắc hẹn',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ActionChip(
            avatar: const Icon(Icons.event, size: 16),
            label: Text(
              widget.editing == null
                  ? _atText(_remindAt)
                  : _remindAt == widget.editing!.remindAt.toLocal()
                  ? widget.editing!.remindAtLabel
                  : _atText(_remindAt),
            ),
            onPressed: _pickAt,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final v in reminderRepeats)
                ChoiceChip(
                  label: Text(_repeatLabel(v)),
                  selected: _repeat == v,
                  onSelected: (_) => setState(() => _repeat = v),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: Text(_isEdit ? 'Lưu' : 'Tạo nhắc hẹn'),
          ),
        ],
      ),
    );
  }

  String _atText(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
