import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.radius = 40,
    this.onTap,
    this.badgeBackgroundColor,
    this.badgeIconColor,
  });

  final String displayName;
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;
  final Color? badgeBackgroundColor;
  final Color? badgeIconColor;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    final hasUrl = url.isNotEmpty;
    final diameter = radius * 2;
    // Vùng chạm rộng hơn avatar (badge camera + dễ bấm trên web).
    final boxSize = diameter + 24;

    Widget content = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: hasUrl ? NetworkImage(url) : null,
          child: hasUrl
              ? null
              : Text(
                  _initials(displayName),
                  style: TextStyle(fontSize: radius * 0.7),
                ),
        ),
        if (onTap != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: badgeBackgroundColor ??
                  Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: badgeIconColor ?? Colors.white,
              ),
            ),
          ),
      ],
    );

    content = SizedBox(width: boxSize, height: boxSize, child: content);

    if (onTap == null) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
