import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/widgets/pinned_messages_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menu khi nhấn giữ tin nhắn (cảm xúc + thao tác).
Future<void> showMessageActions({
  required BuildContext context,
  required ChatMessage message,
  required String? myId,
  required void Function(bool pinned) onSetPinned,
  required void Function(String emoji) onReact,
  required VoidCallback onReply,
  VoidCallback? onRecall,
  VoidCallback? onHide,
  VoidCallback? onSeenDetails,
}) async {
  HapticFeedback.mediumImpact();
  final pinned = message.pinned;
  final recalled = message.recalled;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final primary = scheme.primary;

      void closeThen(VoidCallback action) {
        Navigator.pop(sheetContext);
        action();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Material(
            color: scheme.surface,
            elevation: 12,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MessagePreviewCard(message: message),
                ),
                if (!recalled) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reactionEmojis.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final emoji = reactionEmojis[index];
                        final selected = message.reactions.any(
                          (r) => r.emoji == emoji && r.isMine(myId),
                        );
                        return _ReactionOrb(
                          emoji: emoji,
                          selected: selected,
                          onTap: () => closeThen(() => onReact(emoji)),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                      children: [
                        _MessageActionTile(
                          icon: Icons.reply_rounded,
                          label: 'Trả lời',
                          tint: primary,
                          onTap: () => closeThen(onReply),
                        ),
                        _MessageActionTile(
                          icon: pinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded,
                          label: pinned ? 'Bỏ ghim' : 'Ghim tin nhắn',
                          tint: primary,
                          onTap: () => closeThen(() => onSetPinned(!pinned)),
                        ),
                        if (onSeenDetails != null)
                          _MessageActionTile(
                            icon: Icons.done_all_rounded,
                            label: 'Chi tiết đã xem',
                            tint: primary,
                            onTap: () => closeThen(onSeenDetails),
                          ),
                        if (onRecall != null)
                          _MessageActionTile(
                            icon: Icons.undo_rounded,
                            label: 'Thu hồi tin nhắn',
                            tint: scheme.tertiary,
                            onTap: () => closeThen(onRecall),
                          ),
                      ],
                    ),
                  ),
                ],
                if (onHide != null) ...[
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: _MessageActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Xóa phía tôi',
                      tint: scheme.error,
                      foreground: scheme.error,
                      onTap: () => closeThen(onHide),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ReactionOrb extends StatelessWidget {
  const _ReactionOrb({
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
      color: selected
          ? primary.withValues(alpha: 0.16)
          : const Color(0xFFF0F2F5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 26,
                height: 1,
                shadows: selected
                    ? [
                        Shadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = message.imageUrl?.trim() ?? '';
    final recalled = message.recalled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ] else if (message.content.trim().startsWith('[Vị trí]')) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
          ] else if (message.hasFile) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insert_drive_file_outlined, color: scheme.tertiary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.authorName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recalled
                      ? 'Tin nhắn đã được thu hồi'
                      : pinnedMessagePreview(message),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontStyle: recalled ? FontStyle.italic : FontStyle.normal,
                    color: recalled
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tint,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = foreground ?? scheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}