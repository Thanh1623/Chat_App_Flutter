import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:dio/dio.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MessageModel>> fetchMessages(String roomId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.conversationMessages(roomId),
    );
    final list = response.data ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromJson)
        .toList();
  }

  Future<MessageModel> sendMessage(String roomId, String content) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(roomId),
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data ?? {});
  }

  Future<void> markRead(String roomId, String messageId) async {
    await _dio.post<void>(
      ApiEndpoints.markRoomRead(roomId),
      data: {'messageId': messageId},
    );
  }
}
