import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/presentation/profile_avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Gọi trực tiếp từ [onTap] — web dùng file input sync (xem profile_avatar_picker_web).
Future<void> pickAndUploadProfileAvatar(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final file = await pickProfileImageFile();
    if (!context.mounted) return;
    if (file == null) return;

    await _uploadPickedFile(context, ref, file);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không mở được thư viện ảnh: $e')),
    );
  }
}

Future<void> _uploadPickedFile(
  BuildContext context,
  WidgetRef ref,
  XFile file,
) async {
  final bytes = await file.readAsBytes();
  if (!context.mounted) return;

  final ok = await ref.read(authControllerProvider.notifier).uploadAvatar(
        bytes: bytes,
        filename: file.name.isNotEmpty ? file.name : 'avatar.jpg',
      );
  if (!context.mounted) return;

  if (ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
    );
  } else {
    final err = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Không tải được ảnh')),
    );
  }
}
