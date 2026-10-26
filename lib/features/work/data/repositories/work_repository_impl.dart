import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/work/data/datasources/work_remote_data_source.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:chat_app/features/work/domain/repositories/work_repository.dart';

class WorkRepositoryImpl implements WorkRepository {
  WorkRepositoryImpl(this._remote);

  final WorkRemoteDataSource _remote;

  @override
  Future<List<WorkTask>> listMine({String scope = 'all'}) async {
    try {
      return await _remote.listMine(scope: scope);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> createTask({
    required String roomId,
    required String title,
    required String assigneeId,
    String? notes,
    DateTime? dueAt,
  }) async {
    try {
      return await _remote.createTask(
        roomId: roomId,
        title: title,
        assigneeId: assigneeId,
        notes: notes,
        dueAt: dueAt,
      );
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ChatMessage> updateTask({
    required String taskId,
    String? status,
    String? title,
    String? notes,
    DateTime? dueAt,
  }) async {
    try {
      return await _remote.updateTask(
        taskId: taskId,
        status: status,
        title: title,
        notes: notes,
        dueAt: dueAt,
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}
