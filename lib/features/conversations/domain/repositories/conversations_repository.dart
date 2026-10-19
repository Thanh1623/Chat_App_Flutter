import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';
import 'package:chat_app/features/conversations/domain/entities/inbox_search.dart';
import 'package:chat_app/features/conversations/domain/entities/room_public.dart';

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

  Future<RoomPublic> updateRoomName(String roomId, String name);

  Future<RoomPublic> uploadRoomAvatar({
    required String roomId,
    required List<int> bytes,
    required String filename,
  });

  Future<List<ContactUser>> fetchRoomMembers(String roomId);

  Future<List<ContactUser>> addRoomMember({
    required String roomId,
    required String userId,
  });

  Future<List<ContactUser>> removeRoomMember({
    required String roomId,
    required String userId,
  });

  Future<InboxSearchResult> searchInbox(String query);
}
