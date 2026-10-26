import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/work/domain/entities/work_task.dart';

abstract interface class WorkRepository {
  Future<List<WorkTask>> listMine({String scope = 'all'});

  Future<ChatMessage> createTask({
    required String roomId,
    required String title,
    required String assigneeId,
    String? notes,
    DateTime? dueAt,
  });

  Future<ChatMessage> updateTask({
    required String taskId,
    String? status,
    String? title,
    String? notes,
    DateTime? dueAt,
  });
}
