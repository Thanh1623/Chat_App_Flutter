import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/presentation/profile_avatar_actions.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).refreshProfile();
    });
  }

  String _teamLabel(String team) {
    switch (team.toLowerCase()) {
      case 'sale':
        return 'Team Sale';
      case 'traffic':
        return 'Team Traffic';
      case 'kho':
        return 'Kho';
      default:
        return team.isEmpty ? '—' : team;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: ProfileAvatar(
              displayName: user?.displayName ?? '?',
              avatarUrl: user?.avatarUrl,
              radius: 44,
              onTap: auth.isLoading
                  ? null
                  : () => pickAndUploadProfileAvatar(context, ref),
            ),
          ),
          Center(
            child: Text(
              'Chạm avatar để đổi ảnh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.displayName ?? '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          if (user != null && user.team.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Chip(
                  label: Text(_teamLabel(user.team)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Chỉnh sửa hồ sơ'),
            subtitle: const Text('Tên, email, ảnh đại diện, mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          const Divider(),

          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
