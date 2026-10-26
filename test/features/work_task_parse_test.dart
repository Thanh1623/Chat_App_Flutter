import 'package:chat_app/features/chat/data/models/message_model.dart';
import 'package:chat_app/features/work/data/models/work_task_model.dart';
import 'package:chat_app/features/work/domain/entities/task_notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkTaskModel parses Nest list row', () {
    final task = WorkTaskModel.fromJson({
      'id': 't1',
      'title': 'Soạn báo cáo tuần',
      'notes': '',
      'status': 'open',
      'dueAt': '2026-10-23T11:00:00.000Z',
      'roomId': 'r1',
      'roomName': 'Sale',
      'messageId': 'm9',
      'creator': {'id': 'u1', 'name': 'Minh', 'avatarUrl': ''},
      'assignee': {'id': 'u2', 'name': 'An', 'avatarUrl': ''},
    }).toEntity();

    expect(task.id, 't1');
    expect(task.title, 'Soạn báo cáo tuần');
    expect(task.roomName, 'Sale');
    expect(task.messageId, 'm9');
    expect(task.creatorName, 'Minh');
    expect(task.assigneeName, 'An');
    expect(task.isDone, isFalse);
  });

  test('MessageModel parses task card payload', () {
    final message = MessageModel.fromJson({
      'id': 'm9',
      'roomId': 'r1',
      'authorName': 'Minh',
      'role': 'user',
      'content': 'Soạn báo cáo tuần',
      'type': 'task',
      'createdAt': '2026-10-23T10:00:00.000Z',
      'task': {
        'id': 't1',
        'title': 'Soạn báo cáo tuần',
        'status': 'open',
        'creatorId': 'u1',
        'assigneeId': 'u2',
        'creatorName': 'Minh',
        'assigneeName': 'An',
      },
    }).toEntity();

    expect(message.isTask, isTrue);
    expect(message.task?.assigneeName, 'An');
    expect(message.task?.isDone, isFalse);
  });

  test('TaskNotice banner preview for assignee on create', () {
    final notice = TaskNotice.fromJson({
      'action': 'created',
      'actorId': 'u1',
      'actorName': 'Minh',
      'highlightMessageId': 'm9',
      'task': {
        'title': 'Soạn báo cáo tuần',
        'status': 'open',
        'roomId': 'r1',
        'creator': {'id': 'u1', 'name': 'Minh'},
        'assignee': {'id': 'u2', 'name': 'An'},
      },
    });
    expect(notice.preview, 'Việc: Soạn báo cáo tuần');
    expect(notice.shouldShowBanner('u2'), isTrue);
    expect(notice.shouldShowBanner('u1'), isFalse);
    expect(notice.messageId, 'm9');
  });
}
