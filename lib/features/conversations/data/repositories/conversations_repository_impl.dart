import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/conversations/data/datasources/conversations_remote_data_source.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';

class ConversationsRepositoryImpl implements ConversationsRepository {
  ConversationsRepositoryImpl(this._remote);

  final ConversationsRemoteDataSource _remote;

  @override
  Future<List<Conversation>> fetchConversations() async {
    try {
      final models = await _remote.fetchConversations();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Conversation> openDirect(String userId) async {
    try {
      final model = await _remote.openDirect(userId);
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      final model = await _remote.createGroup(
        name: name,
        memberIds: memberIds,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await _remote.deleteRoom(roomId);
    } catch (e) {
      throw mapException(e);
    }
  }
}
