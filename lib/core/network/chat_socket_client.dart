import 'dart:async';
import 'dart:convert';

import 'package:chat_app/core/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketClient {
  /// socket là đối tượng socket của client
  io.Socket? _socket;

  /// roomId là id của phòng chat
  String? _roomId;

  /// messages là stream của tin nhắn được gửi từ server
  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messages.stream;

  String? _token;

  /// Kết nối nếu chưa có socket; không reconnect khi token giống và đang connected.
  void ensureConnected({required String token}) {
    if (_socket != null && _token == token && _socket!.connected) {
      return;
    }
    connect(token: token);
  }

  /// connect là phương thức để kết nối tới server
  /// token là token của user
  void connect({required String token}) {
    _token = token;
    _socket?.dispose();
    _socket = null;

    /// io.OptionBuilder là phương thức để tạo đối tượng option builder
    final builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .enableForceNew();

    // Web gửi auth trong handshake JS. iOS (dart:io) thường bỏ auth —
    // Nest đọc thêm header Bearer (xem ChatGateway.readToken).
    if (!kIsWeb) {
      builder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }

    /// io.io là phương thức để tạo đối tượng socket
    /// emit là phương thức để gửi tin nhắn tới server
    /// _socket! là đối tượng socket đã được tạo
    _socket = io.io(Env.socketBaseUrl, builder.build());
    _socket!
      ..onConnect((_) {
        if (kDebugMode) {
          debugPrint('socket connected, join $_roomId');
        }
        final roomId = _roomId;
        if (roomId != null) {
          _socket!.emit('join', roomId);
        }
      })
      ..onConnectError((e) {
        if (kDebugMode) {
          debugPrint('socket connect error: $e');
        }
      })
      ..onDisconnect((_) {
        if (kDebugMode) {
          debugPrint('socket disconnected');
        }
      })
      ..on('message', (data) {
        /// _asJsonMap là phương thức để chuyển đổi đối tượng data thành đối tượng json
        final json = _asJsonMap(data);
        if (json == null) {
          if (kDebugMode) {
            debugPrint('socket message skipped: ${data.runtimeType} $data');
          }
          return;
        }

        /// _messages.add là phương thức để thêm đối tượng json vào stream
        _messages.add(json);
      })
      ..connect();
  }

  // Ghi room; đã connected thì emit('join') vào room đó
  void join(String roomId) {
    _roomId = roomId;
    if (_socket?.connected == true) {
      _socket!.emit('join', roomId);
    }
  }

  void disconnect() {
    _roomId = null;
    _token = null;
    _socket?.dispose();
    _socket = null;
  }

  Map<String, dynamic>? _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return null;
  }
}

// Một client / app; dispose thì disconnect
final chatSocketClientProvider = Provider<ChatSocketClient>((ref) {
  final client = ChatSocketClient();
  ref.onDispose(client.disconnect);
  return client;
});
