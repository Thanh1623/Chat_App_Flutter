import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/news/domain/entities/news_reaction_user.dart';
import 'package:flutter/material.dart';

// Hiển thị sheet cho người dùng để xem danh sách người đã thích
Future<void> showDiaryReactionUsersSheet({
  required BuildContext context,
  required List<NewsReactionUser> items,
  required String? myUserId,
}) {
  // Hiển thị sheet cho người dùng để xem danh sách người đã thích
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        _DiaryReactionUsersSheet(items: items, myUserId: myUserId),
  );
}

// Widget hiển thị danh sách người đã thích
class _DiaryReactionUsersSheet extends StatelessWidget {
  const _DiaryReactionUsersSheet({required this.items, required this.myUserId});

  final List<NewsReactionUser> items;
  final String? myUserId;

  // Hiển thị tên người dùng
  String _displayName(String userId, String name) {
    final mine = myUserId?.trim() ?? '';
    if (mine.isNotEmpty && userId.trim() == mine) return 'Bạn';
    return name;
  }

  // Hiển thị emoji cho loại like
  static String _emojiForKind(String kind) {
    return switch (kind) {
      'love' => '❤️',
      'haha' => '😂',
      'wow' => '😮',
      'sad' => '😢',
      'angry' => '😡',
      _ => '👍',
    };
  }

  // Xây dựng widget hiển thị danh sách người đã thích
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Người đã thích',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Chưa có lượt thích'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final user = item.user;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: DiaryAvatar(
                                name: user.name,
                                url: user.avatarUrl,
                                radius: 20,
                              ),
                              title: Text(_displayName(user.id, user.name)),
                              trailing: Text(_emojiForKind(item.kind)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
