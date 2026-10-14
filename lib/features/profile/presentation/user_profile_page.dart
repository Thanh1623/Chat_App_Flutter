import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: asyncUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
        data: (user) => _ProfileBody(user: user),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final ContactUser user;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final team = _teamLabel(user.team);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Center(
          child: ProfileAvatar(
            displayName: user.name,
            avatarUrl: user.avatarUrl,
            radius: 48,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.mail_outline,
          label: 'Email',
          value: user.email.isEmpty ? '—' : user.email,
          iconColor: primary,
        ),
        if (team.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.groups_outlined,
            label: 'Team',
            value: team,
            iconColor: primary,
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      return team;
  }
}
