import 'package:flutter/material.dart';

class DiaryAvatar extends StatelessWidget {
  const DiaryAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 20,
    this.onTap,
  });

  final String name;
  final String? url;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: trimmed.isNotEmpty ? NetworkImage(trimmed) : null,
      child: trimmed.isEmpty
          ? Text(
              _initials(name),
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
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
