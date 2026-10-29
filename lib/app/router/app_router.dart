import 'package:chat_app/app/presentation/main_shell.dart';
import 'package:chat_app/app/router/chat_route_args.dart';
import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/features/auth/presentation/login_page.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/chat/presentation/chat_page.dart';
import 'package:chat_app/features/contacts/presentation/contacts_page.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/conversations_page.dart';
import 'package:chat_app/features/conversations/presentation/create_group_page.dart';
import 'package:chat_app/features/profile/presentation/edit_profile_page.dart';
import 'package:chat_app/features/profile/presentation/employee_profile_page.dart';
import 'package:chat_app/features/profile/presentation/profile_page.dart';
import 'package:chat_app/features/profile/presentation/user_profile_page.dart';
import 'package:chat_app/features/work/presentation/work_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // ponytail: không watch auth ở đây — mỗi notifyListeners tạo GoRouter mới → shell về tab Tin nhắn
  final authListenable = ref.read(authControllerProvider.notifier);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isBootstrapping) {
        return null;
      }

      final isLoggedIn = auth.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isLoggingIn) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const ConversationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.work,
                builder: (context, state) => const WorkPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contacts,
                builder: (context, state) => const ContactsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.employeeProfile,
        builder: (context, state) => const EmployeeProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.newChat,
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfilePage(userId: userId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['conversationId']!;
          final extra = state.extra;
          if (extra is ChatRouteArgs) {
            return ChatPage(
              conversationId: id,
              title: extra.title,
              canDelete: extra.canDelete,
              isGroup: extra.type == ConversationType.group,
              peerUserId: extra.peerUserId,
            );
          }
          final title = extra is String ? extra : null;
          return ChatPage(conversationId: id, title: title);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
