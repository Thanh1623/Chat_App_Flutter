import 'dart:async';

import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Socket inbox: join các phòng đã load; tin mới → refresh list (debounced).
final conversationsInboxSyncProvider = Provider<void>((ref) {
  final isLoggedIn = ref.watch(
    authControllerProvider.select((auth) => auth.isAuthenticated),
  );
  if (!isLoggedIn) {
    return;
  }

  final token = ref.read(sessionStorageProvider).accessToken;
  if (token == null || token.isEmpty) {
    return;
  }

  final socket = ref.read(chatSocketClientProvider);
  socket.ensureConnected(token: token);

  Timer? debounce;
  final sub = socket.messages.listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidate(conversationsProvider);
    });
  });

  void joinRooms(List<Conversation> conversations) {
    socket.ensureConnected(token: token);
    for (final c in conversations) {
      socket.join(c.id);
    }
  }

  ref.listen(conversationsProvider, (previous, next) {
    next.whenData(joinRooms);
  }, fireImmediately: true);

  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
  });
});
