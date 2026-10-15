import 'package:flutter/material.dart';

class ChatMessageAvatar extends StatelessWidget {
  const ChatMessageAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.onTap,
    this.radius = 16,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              _initials(displayName),
              style: TextStyle(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
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
