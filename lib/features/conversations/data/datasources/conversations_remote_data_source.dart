import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/conversations/data/models/conversation_model.dart';
import 'package:dio/dio.dart';

class ConversationsRemoteDataSource {
  const ConversationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ConversationModel>> fetchConversations() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.conversations);
    final list = response.data ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
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
}
