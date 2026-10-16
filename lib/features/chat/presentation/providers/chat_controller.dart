import 'dart:async';

import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/chat/data/providers/chat_repository_provider.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// chatControllerProvider là cách để provider cho chat controller
final chatControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ChatController, String>((ref, roomId) {
      final controller = ChatController(ref, roomId);
      controller.load();
      return controller;
    });

class ChatController extends ChangeNotifier {
  ChatController(this._ref, this.roomId);

  static const _pageSize = 80;

  final Ref _ref;
  final String roomId;

  List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _sending = false;
  bool _hasMore = false;
  String? _nextCursor;
  String? _error;

  /// Giữ subscription để lúc thoát phòng thì cancel (tránh leak).
  StreamSubscription<ChatMessage>? _socketSub;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get isSending => _sending;
  bool get hasMore => _hasMore;
  String? get error => _error;

  ChatRepository get _repo => _ref.read(chatRepositoryProvider);

  /// load là phương thức để load tin nhắn từ server
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _repo.fetchMessages(roomId, limit: _pageSize);
      _messages = page.items.reversed.toList();
      _hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
      await _markLatestRead();
      _startRealtime();
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty) return;

    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.fetchMessages(
        roomId,
        limit: _pageSize,
        cursor: cursor,
      );
      final existing = {for (final m in _messages) m.id};
      final older = page.items.reversed.where((m) => !existing.contains(m.id));
      _messages = [..._messages, ...older];
      _hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// _startRealtime là phương thức để start realtime
  void _startRealtime() {
    final token = _ref.read(sessionStorageProvider).accessToken;
    if (token == null || token.isEmpty) return;

    final socket = _ref.read(chatSocketClientProvider);
    socket.ensureConnected(token: token);
    socket.join(roomId);

    _socketSub?.cancel();
    _socketSub = _repo.watchMessages(roomId).listen(_onSocketMessage);
  }

  /// _onSocketMessage là phương thức để xử lý tin nhắn từ server
  void _onSocketMessage(ChatMessage incoming) {
    _addIfNew(incoming);
    _markLatestRead();
  }

  /// _addIfNew là phương thức để thêm tin nhắn mới vào danh sách tin nhắn
  /// chống duplicate
  void _addIfNew(ChatMessage incoming) {
    if (incoming.id.isEmpty) return;
    if (_messages.any((m) => m.id == incoming.id)) return;
    _messages = [incoming, ..._messages];
    notifyListeners();
  }

  /// send là phương thức để gửi tin nhắn tới server
  Future<void> send(String content) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final sent = await _repo.sendMessage(roomId, content);
      // Socket thường echo trước khi POST trả về — cùng id thì không thêm lần 2.
      _addIfNew(sent);
      await _markLatestRead();
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  String? _optionalCaption(String? caption) {
    final text = caption?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<void> sendImage({
    required List<int> bytes,
    required String filename,
    String? caption,
  }) async {
    await sendImages(
      items: [(bytes: bytes, filename: filename)],
      caption: caption,
    );
  }

  Future<void> sendFiles({
    required List<({List<int> bytes, String filename})> items,
    String? caption,
  }) async {
    if (items.isEmpty) return;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      for (final item in items) {
        final sent = await _repo.sendFileMessage(
          roomId,
          bytes: item.bytes,
          filename: item.filename,
        );
        _addIfNew(sent);
      }
      final text = _optionalCaption(caption);
      if (text != null) {
        final sent = await _repo.sendMessage(roomId, text);
        _addIfNew(sent);
      }
      await _markLatestRead();
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> sendImages({
    required List<({List<int> bytes, String filename})> items,
    String? caption,
  }) async {
    if (items.isEmpty) return;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      for (final item in items) {
        final sent = await _repo.sendImageMessage(
          roomId,
          bytes: item.bytes,
          filename: item.filename,
        );
        _addIfNew(sent);
      }
      final text = _optionalCaption(caption);
      if (text != null) {
        final sent = await _repo.sendMessage(roomId, text);
        _addIfNew(sent);
      }
      await _markLatestRead();
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> _markLatestRead() async {
    if (_messages.isEmpty) return;
    final latest = _messages.first;
    if (latest.id.isEmpty) return;
    try {
      await _repo.markRead(roomId, latest.id);
      _ref.read(conversationsInboxProvider.notifier).refreshInbox();
    } catch (_) {
      // ponytail: read receipt không chặn chat
    }
  }

  /// dispose là phương thức để dispose controller
  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
