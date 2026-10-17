import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

String pinnedMessagePreview(ChatMessage message) {
  final text = message.content.trim();
  if (text.isNotEmpty) return text;
  if (message.hasImage) return 'Ảnh';
  if (message.hasFile) {
    final name = message.fileName?.trim() ?? '';
    return name.isEmpty ? 'Tệp đính kèm' : name;
  }
  return 'Tin đã ghim';
}

String pinnedMessageTime(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return hm;
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $hm';
}

Future<void> showPinMessageActions({
  required BuildContext context,
  required ChatMessage message,
  required String? myId,
  required void Function(bool pinned) onSetPinned,
  required void Function(String emoji) onReact,
}) async {
  HapticFeedback.mediumImpact();
  final pinned = message.pinned;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: scheme.surface,
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PinPreviewChip(message: message),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final emoji in reactionEmojis)
                        _ReactionPickButton(
                          emoji: emoji,
                          selected: message.reactions.any(
                            (r) => r.emoji == emoji && r.isMine(myId),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            onReact(emoji);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onSetPinned(!pinned);
                      },
                      icon: Icon(
                        pinned ? Icons.push_pin_outlined : Icons.push_pin,
                      ),
                      label: Text(pinned ? 'Bỏ ghim' : 'Ghim tin nhắn'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReactionPickButton extends StatelessWidget {
  const _ReactionPickButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withValues(alpha: 0.14) : const Color(0xFFF4F6F8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}

Future<void> showPinnedMessageDetail({
  required BuildContext context,
  required String roomId,
  required String messageId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => _PinnedMessageDetailSheet(
        roomId: roomId,
        messageId: messageId,
        scrollController: scroll,
      ),
    ),
  );
}

Future<void> showPinnedMessagesSheet({
  required BuildContext context,
  required String roomId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.34,
      maxChildSize: 0.92,
      builder: (context, scroll) => PinnedMessagesSheet(
        roomId: roomId,
        scrollController: scroll,
      ),
    ),
  );
}

class PinnedMessagesBanner extends ConsumerWidget {
  const PinnedMessagesBanner({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(chatControllerProvider(roomId)).pinned;
    if (pinned.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final latest = pinned.first;
    final extra = pinned.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () =>
                showPinnedMessagesSheet(context: context, roomId: roomId),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Container(width: 3, color: scheme.primary),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: 0.55,
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extra > 0
                              ? 'Tin đã ghim · ${pinned.length}'
                              : 'Tin đã ghim',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${latest.authorName}: ${pinnedMessagePreview(latest)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.chevron_right, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
      ],
    );
  }
}

class PinnedMessagesSheet extends ConsumerWidget {
  const PinnedMessagesSheet({
    super.key,
    required this.roomId,
    this.scrollController,
  });

  final String roomId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(chatControllerProvider(roomId)).pinned;
    if (pinned.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: 0.55,
                    child: Icon(Icons.push_pin, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tin đã ghim',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                itemCount: pinned.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final message = pinned[index];
                  return _PinnedMessageTile(
                    message: message,
                    onOpen: () => showPinnedMessageDetail(
                      context: context,
                      roomId: roomId,
                      messageId: message.id,
                    ),
                    onUnpin: () => ref
                        .read(chatControllerProvider(roomId).notifier)
                        .setPinned(message, pinned: false),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinPreviewChip extends StatelessWidget {
  const _PinPreviewChip({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final imageUrl = message.imageUrl?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.authorName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pinnedMessagePreview(message),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedMessageTile extends StatelessWidget {
  const _PinnedMessageTile({
    required this.message,
    required this.onOpen,
    required this.onUnpin,
  });

  final ChatMessage message;
  final VoidCallback onOpen;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = message.imageUrl?.trim() ?? '';
    final fileUrl = message.fileUrl?.trim() ?? '';
    final text = message.content.trim();
    final longText = text.length > 90;

    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      fileUrl.isNotEmpty
                          ? Icons.insert_drive_file_outlined
                          : Icons.chat_bubble_outline,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: message.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: '  ${pinnedMessageTime(message.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pinnedMessagePreview(message),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: fileUrl.isNotEmpty
                            ? scheme.primary
                            : Colors.black87,
                      ),
                    ),
                    if (longText)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Xem toàn bộ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUnpin,
                child: const Text('Bỏ ghim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedMessageDetailSheet extends ConsumerWidget {
  const _PinnedMessageDetailSheet({
    required this.roomId,
    required this.messageId,
    this.scrollController,
  });

  final String roomId;
  final String messageId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(chatControllerProvider(roomId)).pinned;
    ChatMessage? message;
    for (final item in pinned) {
      if (item.id == messageId) {
        message = item;
        break;
      }
    }
    if (message == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final imageUrl = message.imageUrl?.trim() ?? '';
    final fileUrl = message.fileUrl?.trim() ?? '';
    final text = message.content.trim();

    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          pinnedMessageTime(message.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (text.isNotEmpty)
                    IconButton(
                      tooltip: 'Sao chép',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  TextButton(
                    onPressed: () => ref
                        .read(chatControllerProvider(roomId).notifier)
                        .setPinned(message!, pinned: false),
                    child: const Text('Bỏ ghim'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (imageUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _openPinnedImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fileUrl.isNotEmpty) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.insert_drive_file_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(
                        message.fileName?.trim().isNotEmpty == true
                            ? message.fileName!.trim()
                            : 'Tệp đính kèm',
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openPinnedFile(context, fileUrl),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (text.isNotEmpty)
                    SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Colors.black87,
                      ),
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

void _openPinnedImage(BuildContext context, String url) {
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

Future<void> _openPinnedFile(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được tệp')),
    );
  }
}
