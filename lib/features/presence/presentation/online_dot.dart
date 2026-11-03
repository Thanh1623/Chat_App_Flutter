import 'package:chat_app/features/presence/presentation/presence_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const onlineGreen = Color(0xFF31A24C);

/// Chấm xanh góc dưới-phải avatar khi [userId] đang online.
class OnlineDot extends ConsumerWidget {
  const OnlineDot({
    super.key,
    required this.userId,
    required this.child,
    this.size = 12,
  });

  final String? userId;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isUserOnlineProvider(userId));
    if (!online) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onlineGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
