import 'package:chat_app/features/work/domain/entities/work_task.dart';
import 'package:chat_app/features/work/presentation/providers/task_due_banner_provider.dart';
import 'package:chat_app/features/work/presentation/widgets/task_due_banners.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WorkTask _task(Duration fromNow) => WorkTask(
      id: 't1',
      title: 'Gửi báo cáo',
      status: 'open',
      roomId: 'r1',
      creatorId: 'a',
      assigneeId: 'me',
      dueAt: DateTime.now().add(fromNow),
    );

Widget _app(List<WorkTask> tasks, {void Function(WorkTask)? onOpen}) {
  return ProviderScope(
    overrides: [dueSoonTasksProvider.overrideWith((ref) => tasks)],
    child: MaterialApp(
      // Giống app.dart: khung bọc nằm trong builder, TRÊN Navigator.
      builder: (context, child) => TaskDueBannerFrame(
        onOpenTask: onOpen ?? (_) {},
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Trang')),
        body: const Text('nội dung'),
      ),
    ),
  );
}

void main() {
  testWidgets('hiện banner trên mọi trang và dựng không lỗi', (tester) async {
    await tester.pumpWidget(_app([_task(const Duration(minutes: 10))]));
    expect(tester.takeException(), isNull);
    expect(find.text('Gửi báo cáo'), findsOneWidget);
    expect(find.text('Trang'), findsOneWidget);
    expect(find.textContaining('là hết hạn'), findsOneWidget);
  });

  testWidgets('quá hạn thì báo đã quá hạn', (tester) async {
    await tester.pumpWidget(_app([_task(const Duration(minutes: -5))]));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Đã quá hạn'), findsOneWidget);
  });

  testWidgets('không có việc thì không hiện banner', (tester) async {
    await tester.pumpWidget(_app(const []));
    expect(tester.takeException(), isNull);
    expect(find.text('Gửi báo cáo'), findsNothing);
    expect(find.text('nội dung'), findsOneWidget);
  });

  testWidgets('bấm banner gọi onOpenTask', (tester) async {
    WorkTask? opened;
    await tester.pumpWidget(
      _app([_task(const Duration(minutes: 10))], onOpen: (t) => opened = t),
    );
    await tester.tap(find.text('Gửi báo cáo'));
    expect(opened?.id, 't1');
  });
}
