import 'package:chat_app/app/router/app_router.dart';
import 'package:chat_app/app/theme/app_theme.dart';
import 'package:chat_app/app/theme/theme_controller.dart';
import 'package:chat_app/features/work/presentation/widgets/incoming_task_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final accent = ref.watch(themeControllerProvider).accent;

    return MaterialApp.router(
      title: 'Chat App',
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return IncomingTaskBannerHost(child: child ?? const SizedBox.shrink());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
