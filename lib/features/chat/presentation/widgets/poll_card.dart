import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PollCard extends ConsumerStatefulWidget {
  const PollCard({super.key, required this.message, required this.myId});

  final ChatMessage message;
  final String? myId;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  bool _busy = false;
  bool _showAdd = false;
  final _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  ChatPoll get _poll => widget.message.poll!;

  bool get _isCreator {
    final id = widget.myId?.trim() ?? '';
    return id.isNotEmpty && id == _poll.creatorId;
  }

  Set<String> get _myIds {
    final id = widget.myId?.trim() ?? '';
    if (id.isEmpty) return {};
    return {
      for (final o in _poll.options)
        if (o.voterIds.contains(id)) o.id,
    };
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(String optionId) async {
    if (_poll.closed) return;
    await _run(() {
      return ref
          .read(chatControllerProvider(widget.message.roomId).notifier)
          .votePoll(widget.message, optionId);
    });
  }

  Future<void> _addOption() async {
    final text = _add.text.trim();
    if (text.isEmpty) return;
    await _run(() async {
      await ref
          .read(chatControllerProvider(widget.message.roomId).notifier)
          .addPollOption(widget.message, text);
      if (!mounted) return;
      _add.clear();
      setState(() => _showAdd = false);
    });
  }

  Future<void> _close() async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Khóa bình chọn?',
      message: 'Sau khi khóa, không ai bình chọn được nữa.',
      confirmLabel: 'Khóa',
    );
    if (!ok || !mounted) return;
    await _run(() {
      return ref
          .read(chatControllerProvider(widget.message.roomId).notifier)
          .closePoll(widget.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.message.poll;
    if (poll == null) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    final maxVoters = poll.totalVoters < 1 ? 1 : poll.totalVoters;
    final canAdd =
        !poll.closed &&
        poll.options.length < 20 &&
        (poll.allowAddOptions || _isCreator);
    final canClose = !poll.closed && _isCreator;

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
              poll.closed ? 'BÌNH CHỌN · ĐÃ KHÓA' : 'BÌNH CHỌN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: poll.closed ? Colors.orange : primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              poll.question,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              poll.multiple ? 'Chọn nhiều phương án' : 'Chọn một phương án',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            for (final opt in poll.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PollOptionRow(
                  option: opt,
                  selected: _myIds.contains(opt.id),
                  percent: opt.count / maxVoters,
                  multiple: poll.multiple,
                  closed: poll.closed,
                  onTap: _busy ? null : () => _vote(opt.id),
                ),
              ),
            if (canAdd) ...[
              if (_showAdd)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _add,
                        enabled: !_busy,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: 'Phương án mới',
                          isDense: true,
                          counterText: '',
                        ),
                        onSubmitted: (_) => _addOption(),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _addOption,
                      child: const Text('Thêm'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _showAdd = false),
                      child: const Text('Hủy'),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () => setState(() => _showAdd = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm phương án'),
                ),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      '${poll.totalVoters} người đã bình chọn',
                      if (poll.closed)
                        'Đã kết thúc'
                      else if (poll.closesAt != null)
                        'Hết hạn ${_due(poll.closesAt!)}',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                if (canClose)
                  TextButton(
                    onPressed: _busy ? null : _close,
                    child: const Text('Khóa'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _due(DateTime due) {
    final d = due.toLocal();
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hm';
  }
}

class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.option,
    required this.selected,
    required this.percent,
    required this.multiple,
    required this.closed,
    required this.onTap,
  });

  final ChatPollOption option;
  final bool selected;
  final double percent;
  final bool multiple;
  final bool closed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: closed ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    multiple
                        ? (selected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank)
                        : (selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off),
                    size: 20,
                    color: closed ? Colors.black38 : primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(option.text)),
                  Text(
                    '${option.count}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
