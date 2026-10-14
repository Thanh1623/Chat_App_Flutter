import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/file_multipart.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/chat/data/models/room_file_model.dart';
import 'package:chat_app/features/chat/data/models/room_image_model.dart';
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

  Future<MessageModel> sendMessage(
    String roomId, {
    String? content,
    String? imageId,
    String? fileId,
  }) async {
    final data = <String, dynamic>{};
    final text = content?.trim() ?? '';
    if (text.isNotEmpty) {
      data['content'] = text;
    }
    if (imageId != null && imageId.isNotEmpty) {
      data['imageId'] = imageId;
    }
    if (fileId != null && fileId.isNotEmpty) {
      data['fileId'] = fileId;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(roomId),
      data: data,
    );
    return MessageModel.fromJson(response.data ?? {});
  }

  Future<RoomImageModel> uploadRoomImage({
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
      ApiEndpoints.roomImages(roomId),
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return RoomImageModel.fromJson(response.data ?? {});
  }

  Future<RoomFileModel> uploadRoomFile({
    required String roomId,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: fileMediaTypeFromFilename(filename),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.roomFiles(roomId),
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return RoomFileModel.fromJson(response.data ?? {});
  }

  Future<void> markRead(String roomId, String messageId) async {
    await _dio.post<void>(
      ApiEndpoints.markRoomRead(roomId),
      data: {'messageId': messageId},
    );
  }
}
