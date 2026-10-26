import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/work/data/models/work_task_model.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:dio/dio.dart';

class WorkRemoteDataSource {
  const WorkRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<WorkTask>> listMine({String scope = 'all'}) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.myTasks,
      queryParameters: {'scope': scope},
    );
    final data = response.data;
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((item) => WorkTaskModel.fromJson(Map<String, dynamic>.from(item)))
        .map((m) => m.toEntity())
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Future<ChatMessage> createTask({
    required String roomId,
    required String title,
    required String assigneeId,
    String? notes,
    DateTime? dueAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.roomTasks(roomId),
      data: {
        'title': title,
        'assigneeId': assigneeId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
      },
    );
    return MessageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<ChatMessage> updateTask({
    required String taskId,
    String? status,
    String? title,
    String? notes,
    DateTime? dueAt,
  }) async {
    final data = <String, dynamic>{
      'status': ?status,
      'title': ?title,
      'notes': ?notes,
      if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.task(taskId),
      data: data,
    );
    return MessageModel.fromJson(response.data ?? {}).toEntity();
  }
}
