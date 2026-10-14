import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/conversations/data/models/conversation_model.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/entities/conversations_page.dart';
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
          .where(_hasConversationMessage)
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
        .where(_hasConversationMessage)
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

  bool _hasConversationMessage(Conversation conversation) {
    return conversation.lastMessagePreview.trim().isNotEmpty;
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
}
