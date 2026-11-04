import 'package:chat_app/app/router/app_router.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/app/session_reset.dart';
import 'package:chat_app/app/theme/app_theme.dart';
import 'package:chat_app/app/theme/theme_controller.dart';
import 'package:chat_app/features/work/presentation/widgets/incoming_task_banner.dart';
import 'package:chat_app/features/work/presentation/widgets/task_due_banners.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionResetProvider);
    final router = ref.watch(appRouterProvider);
    final accent = ref.watch(themeControllerProvider).accent;

    return MaterialApp.router(
      title: 'Chat App',
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return IncomingTaskBannerHost(
          child: TaskDueBannerFrame(
            onOpenTask: (task) {
              if (task.roomId.isEmpty) return;
              var path = AppRoutes.chatPath(task.roomId);
              final messageId = task.messageId?.trim() ?? '';
              if (messageId.isNotEmpty) path = '$path?m=$messageId';
              router.push(path, extra: task.roomName);
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
