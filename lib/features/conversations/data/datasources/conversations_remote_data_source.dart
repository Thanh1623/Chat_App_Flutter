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
}
