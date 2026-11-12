import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:flutter/material.dart';

bool isOwnDiaryPost(DiaryPost post, String? userId) {
  if (userId == null || userId.isEmpty) return false;
  final id = post.author.id;
  return id == userId && id != 'fb' && id != 'news';
}

Future<void> showDiaryPostMenu(
  BuildContext context, {
  required VoidCallback onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
          ],
        ),
      );
    },
  );
}
