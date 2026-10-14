import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/chat_file_format.dart';
import 'package:chat_app/features/chat/presentation/chat_file_send.dart';
import 'package:chat_app/features/chat/presentation/chat_image_send.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    this.title,
    this.canDelete = false,
  });

  final String conversationId;
  final String? title;
  final bool canDelete;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();

  @override
  void dispose() {
    _composerFocus.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    await ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .send(text);
  }

  Future<void> _pickImage() async {
    final caption = _composer.text.trim();
    if (caption.isNotEmpty) {
      _composer.clear();
    }
    await pickAndSendChatImage(
      context,
      ref,
      widget.conversationId,
      caption: caption.isEmpty ? null : caption,
    );
  }

  Future<void> _pickFile() async {
    final caption = _composer.text.trim();
    if (caption.isNotEmpty) {
      _composer.clear();
    }
    await pickAndSendChatFiles(
      context,
      ref,
      widget.conversationId,
      caption: caption.isEmpty ? null : caption,
    );
  }

  Future<void> _confirmDeleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhóm?'),
        content: const Text(
          'Toàn bộ tin nhắn trong nhóm sẽ bị xóa. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref
          .read(conversationsRepositoryProvider)
          .deleteRoom(widget.conversationId);
      ref.invalidate(conversationsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionStorageProvider).user?.id;
    final roomId = widget.conversationId;
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.invalidate(conversationsProvider);
        }
      },
      child: Scaffold(
      backgroundColor: primary.withValues(alpha: 0.08),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Chat'),
        actions: [
          if (widget.canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') _confirmDeleteGroup();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa nhóm'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final chat = ref.watch(chatControllerProvider(roomId));
                return _MessageList(
                  chat: chat,
                  myId: myId,
                  onRetry: () =>
                      ref.read(chatControllerProvider(roomId).notifier).load(),
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final chat = ref.watch(chatControllerProvider(roomId));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chat.error != null && chat.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Text(
                        chat.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  _MessageComposer(
                    controller: _composer,
                    focusNode: _composerFocus,
                    sending: chat.isSending,
                    onSend: _send,
                    onPickImage: _pickImage,
                    onPickFile: _pickFile,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.chat,
    required this.myId,
    required this.onRetry,
  });

  final ChatController chat;
  final String? myId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.error != null && chat.messages.isEmpty) {
      return ErrorView(message: chat.error!, onRetry: onRetry);
    }
    if (chat.messages.isEmpty) {
      return const Center(child: Text('Chưa có tin nhắn'));
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMine: myId != null && message.userId == myId,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.authorName,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              _BubbleBody(message: message, isMine: isMine),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(
                  timeLabel,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isMine
        ? primary
        : message.isAgent
            ? const Color(0xFFFFF3E0)
            : Colors.white;
    final textColor = isMine ? Colors.white : Colors.black87;
    final hasText = message.content.trim().isNotEmpty;
    final url = message.imageUrl?.trim() ?? '';
    final fileUrl = message.fileUrl?.trim() ?? '';
    final mediaOnly = (message.hasImage || message.hasFile) && !hasText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mediaOnly && message.hasImage ? Colors.white : bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fileUrl.isNotEmpty)
              Material(
                color: isMine ? Colors.white.withValues(alpha: 0.12) : Colors.black12,
                child: InkWell(
                  onTap: () => _openFile(context, fileUrl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.62,
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMine ? Colors.white : primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.fileName?.trim().isNotEmpty == true
                                      ? message.fileName!.trim()
                                      : 'Tệp đính kèm',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        isMine ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (message.fileSizeBytes != null &&
                                    message.fileSizeBytes! > 0)
                                  Text(
                                    formatFileSize(message.fileSizeBytes!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: isMine ? Colors.white70 : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (url.isNotEmpty)
              GestureDetector(
                onTap: () => _openImage(context, url),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  message.content,
                  style: TextStyle(color: textColor, height: 1.35),
                  softWrap: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tệp')),
      );
    }
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: sending ? null : onPickImage,
                icon: Icon(Icons.image_outlined, color: primary),
                tooltip: 'Gửi ảnh',
              ),
              IconButton(
                onPressed: sending ? null : onPickFile,
                icon: Icon(Icons.attach_file, color: primary),
                tooltip: 'Gửi tệp',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Tin nhắn',
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
