import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/presentation/profile_avatar_actions.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: user?.displayName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authControllerProvider).user;
    final name = _name.text.trim();
    final email = _email.text.trim();

    String? password;
    String? currentPassword;
    if (_changePassword) {
      password = _newPassword.text;
      currentPassword = _currentPassword.text;
    }

    final nameArg =
        user == null || name != user.displayName ? name : null;
    final emailArg = user == null || email != (user.email ?? '') ? email : null;

    // Avatar đã lưu qua POST /auth/me/avatar — BE PATCH từ chối body không đổi.
    if (nameArg == null && emailArg == null && !_changePassword) {
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ')),
      );
      return;
    }

    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          name: nameArg,
          email: emailArg,
          password: password,
          currentPassword: currentPassword,
        );
    if (!mounted) return;
    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ')),
      );
    } else {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Không lưu được')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : _save,
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ProfileAvatar(
                displayName: user?.displayName ?? '',
                avatarUrl: user?.avatarUrl,
                radius: 48,
                onTap: auth.isLoading
                    ? null
                    : () => pickAndUploadProfileAvatar(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () => pickAndUploadProfileAvatar(context, ref),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh đại diện'),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nhập tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nhập email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đổi mật khẩu'),
              value: _changePassword,
              onChanged: (v) => setState(() => _changePassword = v),
            ),
            if (_changePassword) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPassword,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (!_changePassword) return null;
                  if (v == null || v.isEmpty) {
                    return 'Nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassword,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (!_changePassword) return null;
                  if (v == null || v.length < 6) {
                    return 'Ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (!_changePassword) return null;
                  if (v != _newPassword.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
