import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tập id user đang online, cập nhật realtime từ socket (`presence.online`).
final onlineUserIdsProvider =
    NotifierProvider<OnlineUserIdsNotifier, Set<String>>(
      OnlineUserIdsNotifier.new,
    );

class OnlineUserIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final socket = ref.watch(chatSocketClientProvider);
    final sub = socket.presence.listen((ids) => state = ids);
    ref.onDispose(sub.cancel);
    return socket.onlineIds;
  }
}

/// `true` nếu [userId] đang online.
final isUserOnlineProvider = Provider.family<bool, String?>((ref, userId) {
  if (userId == null || userId.isEmpty) return false;
  return ref.watch(
    onlineUserIdsProvider.select((ids) => ids.contains(userId)),
  );
});
