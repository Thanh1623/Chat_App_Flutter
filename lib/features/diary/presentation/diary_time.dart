/// Thời gian tương đối tiếng Việt cho feed nhật ký.
String formatDiaryTime(DateTime at, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final delta = current.difference(at);
  if (delta.isNegative || delta.inSeconds < 45) return 'Vừa xong';
  if (delta.inMinutes < 60) return '${delta.inMinutes} phút trước';
  if (delta.inHours < 24) return '${delta.inHours} giờ trước';
  if (delta.inDays < 7) return '${delta.inDays} ngày trước';
  final dd = at.day.toString().padLeft(2, '0');
  final mm = at.month.toString().padLeft(2, '0');
  return '$dd/$mm/${at.year}';
}

/// Giống `newsTime` trên web (bình luận).
String formatNewsCommentTime(DateTime at, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final minutes = current.difference(at).inMinutes;
  if (minutes < 1) return 'Vừa xong';
  if (minutes < 60) return '$minutes phút';
  if (minutes < 24 * 60) return '${minutes ~/ 60} giờ';
  final dd = at.day.toString().padLeft(2, '0');
  final mm = at.month.toString().padLeft(2, '0');
  final hh = at.hour.toString().padLeft(2, '0');
  final mi = at.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${at.year} $hh:$mi';
}
