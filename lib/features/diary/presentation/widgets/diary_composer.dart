import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:flutter/material.dart';

class DiaryComposer extends StatelessWidget {
  const DiaryComposer({
    super.key,
    required this.userName,
    this.userAvatarUrl,
    required this.onCompose,
    required this.onPickMedia,
    required this.onMoment,
    required this.onMemory,
  });

  final String userName;
  final String? userAvatarUrl;
  final VoidCallback onCompose;
  final VoidCallback onPickMedia;
  final VoidCallback onMoment;
  final VoidCallback onMemory;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DiaryTokens.bannerGradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_stories, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Nhật ký',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  children: [
                    InkWell(
                      onTap: onCompose,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            DiaryAvatar(
                              name: userName,
                              url: userAvatarUrl,
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hôm nay bạn thế nào?',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Row(
                      children: [
                        _ComposerAction(
                          icon: Icons.photo_library_outlined,
                          color: DiaryTokens.photo,
                          label: 'Ảnh/Video',
                          onTap: onPickMedia,
                        ),
                        _ComposerAction(
                          icon: Icons.play_circle_outline,
                          color: DiaryTokens.moment,
                          label: 'Khoảnh khắc',
                          onTap: onMoment,
                        ),
                        _ComposerAction(
                          icon: Icons.hourglass_bottom_outlined,
                          color: DiaryTokens.memory,
                          label: 'Kỷ niệm',
                          onTap: onMemory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF424242),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
