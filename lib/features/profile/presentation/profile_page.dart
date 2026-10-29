import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/app/theme/app_accent.dart';
import 'package:chat_app/app/theme/theme_controller.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/presentation/profile_avatar_actions.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _pageBg = Color(0xFFF4F5F7);

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

  Future<void> _refresh() =>
      ref.read(authControllerProvider.notifier).refreshProfile();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: _pageBg,
      body: RefreshIndicator(
        color: primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              user: user,
              uploading: auth.isLoading,
              onAvatarTap: auth.isLoading
                  ? null
                  : () => pickAndUploadProfileAvatar(context, ref),
              onOpenProfile: () => context.push(AppRoutes.employeeProfile),
            ),
            const SizedBox(height: 12),
            if (user != null) _InfoCard(user: user),
            const SizedBox(height: 12),
            const _ThemeAccentSection(),
            const SizedBox(height: 12),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.badge_outlined,
                  iconColor: primary,
                  iconBg: primary.withValues(alpha: 0.12),
                  title: 'Hồ sơ nhân sự',
                  subtitle: 'Công việc, cá nhân, giấy tờ, gia đình…',
                  onTap: () => context.push(AppRoutes.employeeProfile),
                ),
                const Divider(height: 1, indent: 72),
                _MenuTile(
                  icon: Icons.edit_outlined,
                  iconColor: primary,
                  iconBg: primary.withValues(alpha: 0.12),
                  title: 'Chỉnh sửa tài khoản',
                  subtitle: 'Tên, email, ảnh đại diện, mật khẩu',
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.logout,
                  iconColor: Theme.of(context).colorScheme.error,
                  iconBg: Theme.of(context).colorScheme.errorContainer,
                  title: 'Đăng xuất',
                  titleColor: Theme.of(context).colorScheme.error,
                  showChevron: false,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ThemeAccentSection extends ConsumerWidget {
  const _ThemeAccentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeControllerProvider).accent;
    final primary = Theme.of(context).colorScheme.primary;

    return _MenuGroup(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primary.withValues(alpha: 0.12),
                    child: Icon(Icons.palette_outlined, color: primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Màu giao diện',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Xanh dương, đỏ đô hoặc vàng hổ phách',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final accent in AppAccent.values) ...[
                    Expanded(
                      child: _AccentOption(
                        accent: accent,
                        selected: accent == selected,
                        onTap: () => ref
                            .read(themeControllerProvider.notifier)
                            .setAccent(accent),
                      ),
                    ),
                    if (accent != AppAccent.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentOption extends StatelessWidget {
  const _AccentOption({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent.seed : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
            color: selected ? accent.seed.withValues(alpha: 0.08) : null,
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.seed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.seed.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                accent.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? accent.seed : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.uploading,
    required this.onAvatarTap,
    required this.onOpenProfile,
  });

  final User? user;
  final bool uploading;
  final VoidCallback? onAvatarTap;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? '—';
    final primary = Theme.of(context).colorScheme.primary;

    return ColoredBox(
      color: primary,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 20,
          4,
          22,
        ),
        child: Row(
          children: [
            ProfileAvatar(
              displayName: name,
              avatarUrl: user?.avatarUrl,
              radius: 36,
              onTap: onAvatarTap,
              badgeBackgroundColor: Colors.white,
              badgeIconColor: primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Hồ sơ nhân sự',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              if (uploading) ...[
                                const SizedBox(height: 8),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final email = user.email?.trim() ?? '';
    final team = _teamLabel(user.team);
    final primary = Theme.of(context).colorScheme.primary;
    final rows = <Widget>[
      _InfoRow(
        icon: Icons.mail_outline,
        label: 'Email',
        value: email.isEmpty ? '—' : email,
        iconColor: primary,
      ),
      if (team.isNotEmpty) ...[
        const Divider(height: 1, indent: 56),
        _InfoRow(
          icon: Icons.groups_outlined,
          label: 'Team',
          value: team,
          iconColor: primary,
        ),
      ],
    ];

    return _MenuGroup(children: rows);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
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
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconBg,
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
            )
          : null,
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
