import 'package:chat_app/core/config/env.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          ListTile(
            title: Text(user?.displayName ?? '—'),
            subtitle: Text(user?.email ?? ''),
            leading: const CircleAvatar(child: Icon(Icons.person)),
          ),
          const Divider(),
          ListTile(
            title: const Text('Môi trường'),
            subtitle: Text('${Env.name} · ${Env.apiBaseUrl}'),
          ),
          ListTile(
            title: const Text('Đăng xuất'),
            leading: const Icon(Icons.logout),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
