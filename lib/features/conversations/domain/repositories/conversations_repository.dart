import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';

abstract interface class ConversationsRepository {
  Future<ConversationsPage> fetchConversationsPage({
    int limit = 20,
    String? cursor,
  });

  Future<Conversation> openDirect(String userId);

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  });

  Future<void> deleteRoom(String roomId);

  Future<List<ContactUser>> fetchRoomMembers(String roomId);

  Future<List<ContactUser>> addRoomMember({
    required String roomId,
    required String userId,
  });

  Future<List<ContactUser>> removeRoomMember({
    required String roomId,
    required String userId,
  });
}
