import 'dart:async';

import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/chat/data/providers/chat_repository_provider.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/work/data/providers/work_repository_provider.dart';
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
  StreamSubscription<List<RoomRead>>? _readsSub;
  Timer? _flashTimer;
  String? _flashMessageId;

  List<ChatMessage> _pinned = [];
  List<RoomRead> _reads = [];
  ChatMessage? _replyingTo;

  List<ChatMessage> get messages => _messages;
  List<ChatMessage> get pinned => _pinned;
  List<RoomRead> get reads => _reads;
  ChatMessage? get replyingTo => _replyingTo;
  String? get flashMessageId => _flashMessageId;
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
      try {
        _pinned = await _repo.fetchPinned(roomId);
      } catch (_) {
        _pinned = []; // ponytail: banner ghim không chặn chat
      }
      try {
        _reads = await _repo.fetchReads(roomId);
      } catch (_) {
        _reads = [];
      }
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
    _readsSub?.cancel();
    _readsSub = _repo.watchReads(roomId).listen(_applyReads);
  }

  void _applyReads(List<RoomRead> reads) {
    _reads = reads;
    notifyListeners();
  }

  List<RoomRead> readersOf(String messageId) {
    if (messageId.isEmpty) return const [];
    final myId = _ref.read(sessionStorageProvider).user?.id;
    return _reads
        .where(
          (item) =>
              item.lastReadMessageId == messageId &&
              (myId == null || item.userId != myId),
        )
        .toList();
  }

  void upsertIncoming(ChatMessage incoming) {
    _upsert(incoming, insertIfMissing: true);
  }

  Future<void> createTask({
    required String title,
    required String assigneeId,
    String? notes,
    DateTime? dueAt,
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final sent = await _ref.read(workRepositoryProvider).createTask(
            roomId: roomId,
            title: title,
            assigneeId: assigneeId,
            notes: notes,
            dueAt: dueAt,
          );
      _upsert(sent, insertIfMissing: true);
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

  Future<void> toggleTaskStatus(ChatMessage message) async {
    final task = message.task;
    if (task == null) return;
    try {
      final updated = await _ref.read(workRepositoryProvider).updateTask(
            taskId: task.id,
            status: task.isDone ? 'open' : 'done',
          );
      _upsert(updated, insertIfMissing: false);
    } on Failure catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _onSocketMessage(ChatMessage incoming) {
    if (incoming.id.isEmpty) return;
    final isNew = !_messages.any((m) => m.id == incoming.id);
    _upsert(incoming, insertIfMissing: true);
    if (isNew) _markLatestRead();
  }

  void _upsert(ChatMessage incoming, {required bool insertIfMissing}) {
    if (incoming.id.isEmpty) return;
    final i = _messages.indexWhere((m) => m.id == incoming.id);
    if (i >= 0) {
      _messages = [..._messages]..[i] = incoming;
    } else if (insertIfMissing) {
      // ponytail: ghim tin ngoài trang đang load không được nhảy lên đầu list
      final oldest = _messages.isEmpty ? null : _messages.last;
      final olderThanPage =
          oldest != null && incoming.createdAt.isBefore(oldest.createdAt);
      if (!olderThanPage) {
        _messages = [incoming, ..._messages];
      }
    }
    _syncPinned(incoming);
    notifyListeners();
  }

  void _syncPinned(ChatMessage message) {
    if (message.pinned) {
      final i = _pinned.indexWhere((p) => p.id == message.id);
      if (i >= 0) {
        _pinned = [..._pinned]..[i] = message;
      } else {
        _pinned = [message, ..._pinned];
      }
    } else {
      _pinned = _pinned.where((p) => p.id != message.id).toList();
    }
  }

  Future<void> toggleReaction(ChatMessage message, String emoji) async {
    try {
      final updated = await _repo.reactMessage(
        roomId,
        message.id,
        emoji: emoji,
      );
      _upsert(updated, insertIfMissing: false);
    } on Failure catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // startReply là phương thức để bắt đầu reply
  void startReply(ChatMessage message) {
    if (message.recalled) return;
    _replyingTo = message;
    flashMessage(message.id);
  }

  // flashMessage là phương thức để gửi tin nhắn đã được reply về đầu trang
  void flashMessage(String messageId) {
    if (messageId.isEmpty) return;
    _flashTimer?.cancel();
    _flashMessageId = messageId;
    notifyListeners();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_flashMessageId != messageId) return;
      _flashMessageId = null;
      notifyListeners();
    });
  }

  // clearReply là phương thức để clear reply
  void clearReply() {
    if (_replyingTo == null) return;
    _replyingTo = null;
    notifyListeners();
  }

  Future<void> recallMessage(ChatMessage message) async {
    try {
      final updated = await _repo.recallMessage(roomId, message.id);
      if (_replyingTo?.id == message.id) _replyingTo = null;
      _upsert(updated, insertIfMissing: false);
    } on Failure catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> hideMessage(ChatMessage message) async {
    try {
      await _repo.hideMessage(roomId, message.id);
      _removeLocal(message.id);
    } on Failure catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _removeLocal(String id) {
    _messages = _messages.where((m) => m.id != id).toList();
    _pinned = _pinned.where((p) => p.id != id).toList();
    if (_replyingTo?.id == id) _replyingTo = null;
    notifyListeners();
  }

  Future<void> setPinned(ChatMessage message, {required bool pinned}) async {
    try {
      final updated = await _repo.pinMessage(
        roomId,
        message.id,
        pinned: pinned,
      );
      _upsert(updated, insertIfMissing: false);
    } on Failure catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// send là phương thức để gửi tin nhắn tới server
  Future<void> send(String content) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final sent = await _repo.sendMessage(
        roomId,
        content,
        replyToId: _replyingTo?.id,
      );
      // Socket thường echo trước khi POST trả về — cùng id thì không thêm lần 2.
      _upsert(sent, insertIfMissing: true);
      clearReply();
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
      final replyId = _replyingTo?.id;
      var attached = false;
      for (final item in items) {
        final sent = await _repo.sendFileMessage(
          roomId,
          bytes: item.bytes,
          filename: item.filename,
          replyToId: attached ? null : replyId,
        );
        attached = true;
        _upsert(sent, insertIfMissing: true);
      }
      final text = _optionalCaption(caption);
      if (text != null) {
        final sent = await _repo.sendMessage(
          roomId,
          text,
          replyToId: attached ? null : replyId,
        );
        _upsert(sent, insertIfMissing: true);
      }
      clearReply();
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
      final replyId = _replyingTo?.id;
      var attached = false;
      for (final item in items) {
        final sent = await _repo.sendImageMessage(
          roomId,
          bytes: item.bytes,
          filename: item.filename,
          replyToId: attached ? null : replyId,
        );
        attached = true;
        _upsert(sent, insertIfMissing: true);
      }
      final text = _optionalCaption(caption);
      if (text != null) {
        final sent = await _repo.sendMessage(
          roomId,
          text,
          replyToId: attached ? null : replyId,
        );
        _upsert(sent, insertIfMissing: true);
      }
      clearReply();
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
      _reads = await _repo.markRead(roomId, latest.id);
      _ref.read(conversationsInboxProvider.notifier).refreshInbox();
    } catch (_) {
      // ponytail: read receipt không chặn chat
    }
  }

  /// dispose là phương thức để dispose controller
  @override
  void dispose() {
    _flashTimer?.cancel();
    _socketSub?.cancel();
    _readsSub?.cancel();
    super.dispose();
  }
}
