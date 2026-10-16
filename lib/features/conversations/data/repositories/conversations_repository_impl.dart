import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/conversations/data/datasources/conversations_remote_data_source.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';

class ConversationsRepositoryImpl implements ConversationsRepository {
  ConversationsRepositoryImpl(this._remote);

  final ConversationsRemoteDataSource _remote;

  @override
  Future<ConversationsPage> fetchConversationsPage({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      return await _remote.fetchConversationsPage(limit: limit, cursor: cursor);
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

  @override
  Future<List<ContactUser>> fetchRoomMembers(String roomId) async {
    try {
      return await _remote.fetchRoomMembers(roomId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<ContactUser>> addRoomMember({
    required String roomId,
    required String userId,
  }) async {
    try {
      return await _remote.addRoomMember(roomId: roomId, userId: userId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<ContactUser>> removeRoomMember({
    required String roomId,
    required String userId,
  }) async {
    try {
      return await _remote.removeRoomMember(roomId: roomId, userId: userId);
    } catch (e) {
      throw mapException(e);
    }
  }
}
