import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote, this._socket);

  final ChatRemoteDataSource _remote;
  final ChatSocketClient _socket;

  @override
  /// Lấy tin nhắn từ remote
  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    try {
      final models = await _remote.fetchMessages(roomId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  /// Gửi tin nhắn từ remote
  Future<ChatMessage> sendMessage(String roomId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Tin nhắn không được trống');
    }
    try {
      final model = await _remote.sendMessage(roomId, trimmed);
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> markRead(String roomId, String messageId) async {
    try {
      await _remote.markRead(roomId, messageId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  /// Xem tin nhắn từ socket
  Stream<ChatMessage> watchMessages(String roomId) {
    // _socket.messages là stream của tin nhắn từ socket
    // where là filter của stream
    // map là map của stream
    // map((model) => model.toEntity()) là map của stream
    // toEntity() là convert từ model sang entity
    return _socket.messages
        .where((json) => json['roomId']?.toString() == roomId)
        .map(MessageModel.fromJson)
        .map((model) => model.toEntity());
  }
}
