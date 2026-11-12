import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_compose_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> openDiaryCompose(
  BuildContext context,
  WidgetRef ref, {
  void Function(String message)? onError,
}) async {
  if (!context.mounted) return;

  final submitted = await context.push<bool>(AppRoutes.diaryCompose);

  ref.read(diaryComposeProvider.notifier).reset();

  if (submitted == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng bài.')),
    );
  }
}
