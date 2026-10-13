import 'dart:async';

import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giữ socket + join mọi phòng trong inbox; tin mới → refresh danh sách.
final conversationsInboxSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
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
    debounce = Timer(const Duration(milliseconds: 350), () {
      ref.invalidate(conversationsProvider);
    });
  });

  ref.watch(conversationsProvider).whenData((conversations) {
    socket.ensureConnected(token: token);
    for (final c in conversations) {
      socket.join(c.id);
    }
  });

  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
  });
});
