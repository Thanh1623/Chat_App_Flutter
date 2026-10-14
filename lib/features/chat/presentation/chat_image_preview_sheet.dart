import 'dart:typed_data';

import 'package:chat_app/features/chat/presentation/chat_image_picker_common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _zaloBlue = Color(0xFF0068FF);

class ChatImagePreviewSheet extends StatefulWidget {
  const ChatImagePreviewSheet({
    super.key,
    required this.files,
    this.initialCaption,
  });

  final List<XFile> files;
  final String? initialCaption;

  @override
  State<ChatImagePreviewSheet> createState() => _ChatImagePreviewSheetState();
}

class _ChatImagePreviewSheetState extends State<ChatImagePreviewSheet> {
  late List<XFile> _files;
  late final TextEditingController _caption;
  final _bytes = <String, Uint8List>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _files = List<XFile>.from(widget.files);
    _caption = TextEditingController(text: widget.initialCaption ?? '');
    _loadPreviews();
  }

  Future<void> _loadPreviews() async {
    for (final file in _files) {
      _bytes[file.path] = await file.readAsBytes();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _removeAt(int index) {
    setState(() {
      final removed = _files.removeAt(index);
      _bytes.remove(removed.path);
    });
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
                'Gửi ảnh (${_files.length}/$kMaxChatImagesPerSend)',
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
          if (_loading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa chọn ảnh nào'),
            )
          else
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = _files[index];
                  final data = _bytes[file.path];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: data == null
                            ? const SizedBox(
                                width: 112,
                                height: 112,
                                child: ColoredBox(color: Color(0xFFE0E0E0)),
                              )
                            : Image.memory(
                                data,
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _removeAt(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
              hintText: 'Chú thích (tuỳ chọn, gửi thành tin nhắn sau ảnh)',
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
            onPressed: _files.isEmpty || _loading
                ? null
                : () {
                    Navigator.pop(
                      context,
                      ChatImagePreviewResult(
                        files: List<XFile>.from(_files),
                        caption: _caption.text.trim(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _zaloBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _files.length <= 1
                  ? 'Gửi ảnh'
                  : 'Gửi ${_files.length} ảnh',
            ),
          ),
        ],
      ),
    );
  }
}

class ChatImagePreviewResult {
  const ChatImagePreviewResult({
    required this.files,
    required this.caption,
  });

  final List<XFile> files;
  final String caption;
}
