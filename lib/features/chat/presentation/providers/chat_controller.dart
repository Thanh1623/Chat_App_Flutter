import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/chat/data/providers/chat_repository_provider.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ChatController, String>((ref, roomId) {
  final controller = ChatController(ref, roomId);
  controller.load();
  return controller;
});

class ChatController extends ChangeNotifier {
  ChatController(this._ref, this.roomId);

  final Ref _ref;
  final String roomId;

  List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _loading;
  bool get isSending => _sending;
  String? get error => _error;

  ChatRepository get _repo => _ref.read(chatRepositoryProvider);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _repo.fetchMessages(roomId);
      // ponytail: newest first for ListView reverse:true (index 0 at bottom)
      _messages = items.reversed.toList();
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> send(String content) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final sent = await _repo.sendMessage(roomId, content);
      _messages = [sent, ..._messages];
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
