import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/messages_page.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote, this._socket);

  final ChatRemoteDataSource _remote;
  final ChatSocketClient _socket;

  @override
  Future<MessagesPage> fetchMessages(
    String roomId, {
    int limit = 80,
    String? cursor,
  }) async {
    try {
      return await _remote.fetchMessages(roomId, limit: limit, cursor: cursor);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  /// Gửi tin nhắn từ remote
  Future<ChatMessage> sendMessage(
    String roomId,
    String content, {
    String? replyToId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Tin nhắn không được trống');
    }
    try {
      final model = await _remote.sendMessage(
        roomId,
        content: trimmed,
        replyToId: replyToId,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> sendFileMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
    String? replyToId,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Tệp trống');
    }
    try {
      final uploaded = await _remote.uploadRoomFile(
        roomId: roomId,
        bytes: bytes,
        filename: filename,
      );
      if (uploaded.id.isEmpty) {
        throw StateError('Upload tệp không trả id');
      }
      final model = await _remote.sendMessage(
        roomId,
        fileId: uploaded.id,
        replyToId: replyToId,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> sendImageMessage(
    String roomId, {
    required List<int> bytes,
    required String filename,
    String? caption,
    String? replyToId,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Ảnh trống');
    }
    try {
      final uploaded = await _remote.uploadRoomImage(
        roomId: roomId,
        bytes: bytes,
        filename: filename,
      );
      if (uploaded.id.isEmpty) {
        throw StateError('Upload ảnh không trả id');
      }
      final model = await _remote.sendMessage(
        roomId,
        content: caption,
        imageId: uploaded.id,
        replyToId: replyToId,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<RoomRead>> markRead(String roomId, String messageId) async {
    try {
      return await _remote.markRead(roomId, messageId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<RoomRead>> fetchReads(String roomId) async {
    try {
      return await _remote.fetchReads(roomId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> pinMessage(
    String roomId,
    String messageId, {
    required bool pinned,
  }) async {
    try {
      final model = await _remote.pinMessage(
        roomId,
        messageId,
        pinned: pinned,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> reactMessage(
    String roomId,
    String messageId, {
    required String emoji,
  }) async {
    try {
      final model = await _remote.reactMessage(
        roomId,
        messageId,
        emoji: emoji,
      );
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> recallMessage(String roomId, String messageId) async {
    try {
      final model = await _remote.recallMessage(roomId, messageId);
      return model.toEntity();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> hideMessage(String roomId, String messageId) async {
    try {
      await _remote.hideMessage(roomId, messageId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<ChatMessage>> fetchPinned(String roomId) async {
    try {
      return await _remote.fetchPinned(roomId);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  /// Xem tin nhắn từ socket
  Stream<ChatMessage> watchMessages(String roomId) {
    // _socket.messages là stream của tin nhắn từ socket
    // where là filter của stream
    // map là map của stream
    // map((model) => model.toEntity()) là map của stream
    // toEntity() là convert từ model sang entity
    return _socket.messages
        .where((json) => json['roomId']?.toString() == roomId)
        .map(MessageModel.fromJson)
        .map((model) => model.toEntity());
  }

  @override
  Stream<List<RoomRead>> watchReads(String roomId) {
    return _socket.reads
        .where((json) {
          final id = json['roomId']?.toString();
          return id == null || id.isEmpty || id == roomId;
        })
        .map((json) => parseRoomReads(json['reads'] ?? json));
  }
}
