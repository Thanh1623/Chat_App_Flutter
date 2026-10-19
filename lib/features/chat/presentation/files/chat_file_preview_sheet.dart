import 'package:chat_app/features/chat/presentation/files/chat_file_picker_common.dart';
import 'package:chat_app/features/chat/presentation/files/chat_file_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ChatFilePreviewResult {
  const ChatFilePreviewResult({
    required this.files,
    required this.caption,
  });

  final List<PlatformFile> files;
  final String caption;
}

class ChatFilePreviewSheet extends StatefulWidget {
  const ChatFilePreviewSheet({
    super.key,
    required this.files,
    this.initialCaption,
  });

  final List<PlatformFile> files;
  final String? initialCaption;

  @override
  State<ChatFilePreviewSheet> createState() => _ChatFilePreviewSheetState();
}

class _ChatFilePreviewSheetState extends State<ChatFilePreviewSheet> {
  late List<PlatformFile> _files;
  late final TextEditingController _caption;

  @override
  void initState() {
    super.initState();
    _files = List<PlatformFile>.from(widget.files);
    _caption = TextEditingController(text: widget.initialCaption ?? '');
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _removeAt(int index) {
    setState(() => _files.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Gửi tệp (${_files.length}/$kMaxChatFilesPerSend)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa chọn tệp nào'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _files.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(formatFileSize(file.size)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeAt(index),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Chú thích (tuỳ chọn, gửi thành tin nhắn sau tệp)',
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _files.isEmpty
                ? null
                : () {
                    Navigator.pop(
                      context,
                      ChatFilePreviewResult(
                        files: List<PlatformFile>.from(_files),
                        caption: _caption.text.trim(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _files.length <= 1
                  ? 'Gửi tệp'
                  : 'Gửi ${_files.length} tệp',
            ),
          ),
        ],
      ),
    );
  }
}
