import 'package:chat_app/features/diary/presentation/diary_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 6, 12);

  test('formatDiaryTime uses relative Vietnamese labels', () {
    expect(formatDiaryTime(now.subtract(const Duration(seconds: 10)), now: now), 'Vừa xong');
    expect(formatDiaryTime(now.subtract(const Duration(minutes: 12)), now: now), '12 phút trước');
    expect(formatDiaryTime(now.subtract(const Duration(hours: 2)), now: now), '2 giờ trước');
    expect(formatDiaryTime(now.subtract(const Duration(days: 3)), now: now), '3 ngày trước');
    expect(formatDiaryTime(DateTime(2026, 1, 5, 9), now: now), '05/01/2026');
  });
}
