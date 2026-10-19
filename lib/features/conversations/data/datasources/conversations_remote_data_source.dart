import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/conversations/data/models/conversation_model.dart';
import 'package:chat_app/features/contacts/data/models/contact_user_model.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';
import 'package:chat_app/features/conversations/domain/entities/inbox_search.dart';
import 'package:chat_app/features/conversations/domain/entities/room_public.dart';
import 'package:dio/dio.dart';

class ConversationsRemoteDataSource {
  const ConversationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ConversationsPage> fetchConversationsPage({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.conversations,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final data = response.data;
    if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .map((m) => m.toEntity())
          .where(_includeInInbox)
          .toList();
      return ConversationsPage(items: items, hasMore: false);
    }
    if (data is! Map<String, dynamic>) {
      return const ConversationsPage(items: [], hasMore: false);
    }

    final rawItems = data['data'];
    final meta = data['meta'];
    final list = rawItems is List ? rawItems : const [];
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .map((m) => m.toEntity())
        .where(_includeInInbox)
        .toList();

    var hasMore = false;
    String? nextCursor;
    if (meta is Map<String, dynamic>) {
      hasMore = meta['hasMore'] == true;
      final cursorRaw = meta['nextCursor']?.toString();
      if (cursorRaw != null && cursorRaw.isNotEmpty) {
        nextCursor = cursorRaw;
      }
    }

    return ConversationsPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  bool _includeInInbox(Conversation conversation) {
    if (conversation.type == ConversationType.group) return true;
    return conversation.lastMessagePreview.trim().isNotEmpty;
  }

  Future<List<ContactUser>> fetchRoomMembers(String roomId) async {
    final response =
        await _dio.get<List<dynamic>>(ApiEndpoints.roomMembers(roomId));
    return _parseMembers(response.data);
  }

  Future<List<ContactUser>> addRoomMember({
    required String roomId,
    required String userId,
  }) async {
    final response = await _dio.post<List<dynamic>>(
      ApiEndpoints.roomMembers(roomId),
      data: {'userId': userId},
    );
    return _parseMembers(response.data);
  }

  Future<List<ContactUser>> removeRoomMember({
    required String roomId,
    required String userId,
  }) async {
    final response = await _dio.delete<List<dynamic>>(
      ApiEndpoints.roomMember(roomId, userId),
    );
    return _parseMembers(response.data);
  }

  List<ContactUser> _parseMembers(List<dynamic>? data) {
    return (data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ContactUserModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }

  Future<ConversationModel> openDirect(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.roomsDirect,
      data: {'userId': userId},
    );
    return ConversationModel.fromJson(response.data ?? {});
  }

  Future<ConversationModel> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.createRoom,
      data: {'name': name, 'memberIds': memberIds},
    );
    return ConversationModel.fromJson(response.data ?? {});
  }

  Future<void> deleteRoom(String roomId) async {
    await _dio.delete<void>(ApiEndpoints.deleteRoom(roomId));
  }

  Future<RoomPublic> updateRoomName(String roomId, String name) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.roomSettings(roomId),
      data: {'name': name},
    );
    return RoomPublic.fromJson(response.data ?? {});
  }

  Future<RoomPublic> uploadRoomAvatar({
    required String roomId,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: imageMediaTypeFromFilename(filename),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.roomAvatar(roomId),
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return RoomPublic.fromJson(response.data ?? {});
  }

  Future<InboxSearchResult> searchInbox(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const InboxSearchResult();
    final response = await _dio.get<dynamic>(
      ApiEndpoints.inboxSearch,
      queryParameters: {'q': q},
    );
    return parseInboxSearch(response.data);
  }
}

InboxSearchResult parseInboxSearch(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return const InboxSearchResult();
  }
  final usersRaw = data['users'];
  final roomsRaw = data['rooms'];
  final messagesRaw = data['messages'];
  return InboxSearchResult(
    users: (usersRaw is List ? usersRaw : const [])
        .whereType<Map<String, dynamic>>()
        .map(ContactUserModel.fromJson)
        .map((m) => m.toEntity())
        .toList(),
    rooms: (roomsRaw is List ? roomsRaw : const [])
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .map((m) => m.toEntity())
        .toList(),
    messages: (messagesRaw is List ? messagesRaw : const [])
        .whereType<Map<String, dynamic>>()
        .map(InboxSearchMessage.fromJson)
        .toList(),
  );
}
