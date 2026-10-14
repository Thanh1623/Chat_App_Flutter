import 'package:chat_app/features/chat/presentation/chat_file_picker.dart';
import 'package:flutter/services.dart';
import 'package:chat_app/features/chat/presentation/chat_file_preview_sheet.dart';
import 'package:chat_app/features/chat/presentation/platform_file_bytes.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> pickAndSendChatFiles(
  BuildContext context,
  WidgetRef ref,
  String roomId, {
  String? caption,
}) async {
  try {
    final picked = await pickChatFiles();
    if (!context.mounted || picked.isEmpty) return;

    final result = await showModalBottomSheet<ChatFilePreviewResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ChatFilePreviewSheet(
        files: picked,
        initialCaption: caption,
      ),
    );
    if (!context.mounted || result == null || result.files.isEmpty) return;

    final cap = result.caption.isEmpty ? null : result.caption;
    final items = <({List<int> bytes, String filename})>[];
    for (final file in result.files) {
      final bytes = await readPlatformFileBytes(file);
      if (bytes == null || bytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không đọc được tệp: ${file.name}')),
          );
        }
        return;
      }
      items.add((
        bytes: bytes,
        filename: file.name.isNotEmpty ? file.name : 'file.bin',
      ));
    }
    if (!context.mounted) return;

    await ref.read(chatControllerProvider(roomId).notifier).sendFiles(
          items: items,
          caption: cap,
        );
  } on MissingPluginException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa load plugin chọn tệp. Dừng app và chạy lại flutter run (không chỉ hot restart).',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không gửi được tệp: $e')),
    );
  }
}
