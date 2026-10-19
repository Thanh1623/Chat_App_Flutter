import 'package:chat_app/features/chat/presentation/images/chat_image_picker.dart';
import 'package:chat_app/features/chat/presentation/images/chat_image_preview_sheet.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> pickAndSendChatImage(
  BuildContext context,
  WidgetRef ref,
  String roomId, {
  String? caption,
}) async {
  try {
    final picked = await pickChatImageFiles();
    if (!context.mounted || picked.isEmpty) return;

    final result = await showModalBottomSheet<ChatImagePreviewResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ChatImagePreviewSheet(
        files: picked,
        initialCaption: caption,
      ),
    );
    if (!context.mounted || result == null || result.files.isEmpty) return;

    final cap =
        result.caption.isEmpty ? null : result.caption;
    final items = <({List<int> bytes, String filename})>[];
    for (final file in result.files) {
      items.add((
        bytes: await file.readAsBytes(),
        filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
      ));
    }
    if (!context.mounted) return;

    await ref.read(chatControllerProvider(roomId).notifier).sendImages(
          items: items,
          caption: cap,
        );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không gửi được ảnh: $e')),
    );
  }
}
