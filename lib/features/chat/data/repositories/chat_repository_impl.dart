import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    try {
      final models = await _remote.fetchMessages(roomId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
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
}
