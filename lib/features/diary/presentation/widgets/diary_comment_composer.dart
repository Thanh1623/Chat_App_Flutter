import 'package:chat_app/features/diary/presentation/widgets/diary_comment_tokens.dart';
import 'package:flutter/material.dart';

class DiaryCommentComposer extends StatefulWidget {
  const DiaryCommentComposer({
    super.key,
    required this.placeholder,
    required this.onSubmit,
    required this.onDone,
    this.initial,
    this.submitText,
    this.autoFocus = false,
    this.onCancel,
  });

  final String placeholder;
  final Future<void> Function(String body) onSubmit;
  final VoidCallback onDone;
  final String? initial;
  final String? submitText;
  final bool autoFocus;
  final VoidCallback? onCancel;

  @override
  State<DiaryCommentComposer> createState() => DiaryCommentComposerState();
}

class DiaryCommentComposerState extends State<DiaryCommentComposer> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => focusComposer());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void focusComposer() => _focus.requestFocus();

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(body);
      if (!mounted) return;
      if (widget.initial == null) {
        _controller.clear();
      }
      widget.onDone();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _fieldHeight = 36.0;
  static const _radius = 20.0;
  static const _softBorder = Color(0xFFE4E6EB);

  InputBorder _outlineBorder({Color? color}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide(color: color ?? _softBorder, width: 1),
  );

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;
    final scheme = Theme.of(context).colorScheme;
    final sendIcon = widget.submitText == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            minLines: 1,
            maxLines: 6,
            maxLength: DiaryCommentTokens.maxLength,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, height: 1.25),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
              filled: true,
              fillColor: DiaryCommentTokens.bubble,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              constraints: const BoxConstraints(minHeight: _fieldHeight),
              border: _outlineBorder(),
              enabledBorder: _outlineBorder(),
              focusedBorder: _outlineBorder(color: scheme.primary.withValues(alpha: 0.45)),
              disabledBorder: _outlineBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        if (widget.onCancel != null)
          TextButton(
            onPressed: _sending ? null : widget.onCancel,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, _fieldHeight),
            ),
            child: const Text('Hủy'),
          ),
        FilledButton(
          onPressed: empty || _sending ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: sendIcon
                ? const Size(_fieldHeight, _fieldHeight)
                : const Size(0, _fieldHeight),
            fixedSize: sendIcon
                ? const Size(_fieldHeight, _fieldHeight)
                : null,
            padding: sendIcon
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 14),
            shape: sendIcon
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radius),
                  ),
            visualDensity: VisualDensity.compact,
          ),
          child: _sending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : widget.submitText != null
              ? Text(
                  widget.submitText!,
                  style: const TextStyle(fontSize: 13),
                )
              : const Icon(Icons.send_rounded, size: 18),
        ),
      ],
    );
  }
}