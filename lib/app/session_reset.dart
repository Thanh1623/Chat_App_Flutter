import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/presence/presentation/presence_provider.dart';
import 'package:chat_app/features/profile/presentation/providers/employee_profile_provider.dart';
import 'package:chat_app/features/work/presentation/providers/task_due_banner_provider.dart';
import 'package:chat_app/features/work/presentation/providers/work_tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Xóa mọi state theo từng tài khoản khi đăng xuất, để đăng nhập lại (kể cả
/// tài khoản khác) không còn thấy dữ liệu của phiên trước.
///
/// - Đăng xuất: ngắt socket (dừng presence/realtime của tài khoản cũ).
/// - Đăng nhập lại sau một lần đăng xuất: invalidate các provider cache dữ liệu
///   người dùng (inbox, việc, hồ sơ, danh bạ, online…). Chưa invalidate lúc
///   đăng xuất để tránh gọi API khi token đã bị xóa.
/// - Khởi động app / khôi phục phiên: không làm gì (không có dữ liệu cũ).
final sessionResetProvider = Provider<void>((ref) {
  var signedOut = false;

  ref.listen<String?>(
    authControllerProvider.select((auth) => auth.user?.id),
    (previous, next) {
      if (next == null) {
        if (previous != null) {
          signedOut = true;
          ref.read(chatSocketClientProvider).disconnect();
        }
        return;
      }
      if (!signedOut) return;
      signedOut = false;
      ref.invalidate(conversationsInboxProvider);
      ref.invalidate(inboxSearchProvider);
      ref.invalidate(myTasksProvider);
      ref.invalidate(dismissedTaskBannersProvider);
      ref.invalidate(taskNoticeProvider);
      ref.invalidate(onlineUserIdsProvider);
      ref.invalidate(employeeProfileProvider);
      ref.invalidate(contactSearchProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(chatControllerProvider);
    },
  );
});
