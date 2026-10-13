import 'package:chat_app/core/widgets/unread_count_badge.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_inbox_sync.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _zaloBlue = Color(0xFF0068FF);

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    if (index == 0 || index == 1) {
      ref.invalidate(conversationsProvider);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(conversationsInboxSyncProvider);
    final unreadTotal = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(ref, index),
        indicatorColor: _zaloBlue.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: _NavIcon(
              icon: Icons.chat_bubble_outline,
              unread: unreadTotal,
            ),
            selectedIcon: _NavIcon(
              icon: Icons.chat_bubble,
              unread: unreadTotal,
              selected: true,
            ),
            label: 'Tin nhắn',
          ),
          const NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts, color: _zaloBlue),
            label: 'Danh bạ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _zaloBlue),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.unread,
    this.selected = false,
  });

  final IconData icon;
  final int unread;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 24, color: selected ? _zaloBlue : null),
          if (unread > 0)
            Positioned(
              right: -8,
              top: -5,
              child: Transform.scale(
                scale: 0.72,
                child: UnreadCountBadge(count: unread),
              ),
            ),
        ],
      ),
    );
  }
}
