import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/file_multipart.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/chat/data/models/room_file_model.dart';
import 'package:chat_app/features/chat/data/models/room_image_model.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';
import 'package:dio/dio.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MessagesPage> fetchMessages(
    String roomId, {
    int limit = 80,
    String? cursor,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.conversationMessages(roomId),
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return parseMessagesPage(response.data);
  }

  Future<MessageModel> sendMessage(
    String roomId, {
    String? content,
    String? imageId,
    String? fileId,
    String? replyToId,
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
    if (replyToId != null && replyToId.isNotEmpty) {
      data['replyToId'] = replyToId;
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

  /// đây là API để pin một tin nhắn trong phòng chat
  Future<MessageModel> pinMessage(
    String roomId,
    String messageId, {
    required bool pinned,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.pinMessage(roomId, messageId),
      data: {'pinned': pinned},
    );
    return MessageModel.fromJson(response.data ?? {});
  }

  /// đây là API để lấy danh sách các tin nhắn đã được pin trong phòng chat
  Future<MessageModel> reactMessage(
    String roomId,
    String messageId, {
    required String emoji,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.messageReactions(roomId, messageId),
      data: {'emoji': emoji},
    );
    return MessageModel.fromJson(response.data ?? {});
  }

  Future<MessageModel> recallMessage(String roomId, String messageId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.recallMessage(roomId, messageId),
    );
    return MessageModel.fromJson(response.data ?? {});
  }

  Future<void> hideMessage(String roomId, String messageId) async {
    await _dio.delete<void>(ApiEndpoints.hideMessage(roomId, messageId));
  }

  Future<List<ChatMessage>> fetchPinned(String roomId) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.roomPins(roomId));
    final list = response.data is List ? response.data as List : const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }
}

MessagesPage parseMessagesPage(dynamic data) {
  if (data is List) {
    return MessagesPage(items: _mapMessages(data), hasMore: false);
  }
  if (data is! Map<String, dynamic>) {
    return const MessagesPage(items: [], hasMore: false);
  }

  final rawItems = data['data'];
  final list = rawItems is List ? rawItems : const [];
  var hasMore = false;
  String? nextCursor;
  final meta = data['meta'];
  if (meta is Map<String, dynamic>) {
    hasMore = meta['hasMore'] == true;
    final cursorRaw = meta['nextCursor']?.toString();
    if (cursorRaw != null && cursorRaw.isNotEmpty) {
      nextCursor = cursorRaw;
    }
  }
  return MessagesPage(
    items: _mapMessages(list),
    hasMore: hasMore,
    nextCursor: nextCursor,
  );
}

List<ChatMessage> _mapMessages(List<dynamic> list) {
  return list
      .whereType<Map<String, dynamic>>()
      .map(MessageModel.fromJson)
      .map((m) => m.toEntity())
      .toList();
}
