import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:flutter/material.dart';

class DiaryTopBar extends StatelessWidget {
  const DiaryTopBar({
    super.key,
    required this.searchController,
    required this.userName,
    this.userAvatarUrl,
    required this.onAvatarTap,
    required this.onNotificationTap,
    required this.onGalleryTap,
  });

  final TextEditingController searchController;
  final String userName;
  final String? userAvatarUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0.4,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.paddingOf(context).top + 8,
          8,
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bài viết...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa',
                          onPressed: searchController.clear,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Thư viện ảnh',
              onPressed: onGalleryTap,
              icon: Icon(Icons.photo_library_outlined, color: primary),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: onNotificationTap,
              icon: Icon(Icons.notifications_outlined, color: primary),
            ),
            DiaryAvatar(
              name: userName,
              url: userAvatarUrl,
              radius: 16,
              onTap: onAvatarTap,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
