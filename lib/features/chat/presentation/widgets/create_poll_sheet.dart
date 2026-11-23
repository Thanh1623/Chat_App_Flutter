import 'package:flutter/material.dart';

/** Widget này được sử dụng để tạo bình chọn trong ứng dụng */
Future<CreatePollDraft?> showCreatePollSheet({required BuildContext context}) {
  return showModalBottomSheet<CreatePollDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: const CreatePollSheet(),
    ),
  );
}

class CreatePollDraft {
  const CreatePollDraft({
    required this.question,
    required this.options,
    required this.multiple,
    required this.allowAddOptions,
    this.closesAt,
  });

  final String question;
  final List<String> options;
  final bool multiple;
  final bool allowAddOptions;
  final DateTime? closesAt;
}

class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({super.key});

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  bool _multiple = false;
  bool _allowAddOptions = false;
  DateTime? _closesAt;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  /** _validOptions là danh sách các phương án hợp lệ */
  List<String> get _validOptions {
    final texts = _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty);
    return texts.toList();
  }

  /** _canSubmit là hàm kiểm tra xem có thể submit bình chọn không */
  bool get _canSubmit {
    final q = _question.text.trim();
    final opts = _validOptions;
    if (q.isEmpty || q.length > 200 || opts.length < 2) return false;
    final unique = opts.map((t) => t.toLowerCase()).toSet();
    return unique.length == opts.length;
  }

  /** _submit là hàm submit bình chọn */
  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      CreatePollDraft(
        question: _question.text.trim(),
        options: _validOptions,
        multiple: _multiple,
        allowAddOptions: _allowAddOptions,
        closesAt: _closesAt,
      ),
    );
  }

  /** _addOption là hàm thêm phương án */
  void _addOption() {
    if (_options.length >= 10) return;
    setState(() => _options.add(TextEditingController()));
  }

  /** _removeOption là hàm xóa phương án */
  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options.removeAt(index).dispose();
    });
  }

  /** _pickClosesAt là hàm chọn thời hạn */
  Future<void> _pickClosesAt() async {
    final now = DateTime.now();
    final base = _closesAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    setState(() {
      _closesAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /** _closesText là hàm format thời hạn */
  String _closesText(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SingleChildScrollView(
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
            const Text(
              'Tạo bình chọn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _question,
              autofocus: true,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Câu hỏi bình chọn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các phương án',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        maxLength: 100,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Phương án ${i + 1}',
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(i),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Xóa',
                      ),
                  ],
                ),
              ),
            if (_options.length < 10)
              OutlinedButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Thêm phương án'),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cho chọn nhiều phương án'),
              value: _multiple,
              onChanged: (v) => setState(() => _multiple = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cho thành viên thêm phương án'),
              value: _allowAddOptions,
              onChanged: (v) => setState(() => _allowAddOptions = v),
            ),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(
                    _closesAt == null
                        ? 'Thời hạn (không bắt buộc)'
                        : _closesText(_closesAt!),
                  ),
                  onPressed: _pickClosesAt,
                ),
                ChoiceChip(
                  label: const Text('Không hạn'),
                  selected: _closesAt == null,
                  onSelected: (_) => setState(() => _closesAt = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Tạo bình chọn'),
            ),
          ],
        ),
      ),
    );
  }
}
