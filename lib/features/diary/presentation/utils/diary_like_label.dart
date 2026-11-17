import 'package:chat_app/features/news/domain/entities/news_reaction_user.dart';

/// Tên “người đầu” để hiển thị: ưu tiên người khác mình trong list API.
String? primaryLikerName(
  List<NewsReactionUser> items, {
  required String? myUserId,
}) {
  final mine = myUserId?.trim() ?? '';
  for (final item in items) {
    final id = item.user.id.trim();
    if (mine.isNotEmpty && id == mine) continue;
    final name = item.user.name.trim();
    if (name.isNotEmpty) return name;
  }
  if (items.isEmpty) return null;
  return items.first.user.name.trim().isEmpty ? null : items.first.user.name;
}

/// Tạo label cho số lượng like và người like đầu tiên
String diaryLikeSummaryLabel({
  required int likeCount,
  required bool likedByMe,
  String? topName,
}) {
  if (likeCount <= 0) return '';
  if (likedByMe && likeCount == 1) return 'Bạn';
  if (likedByMe) {
    final others = likeCount - 1;
    if (topName != null && topName.isNotEmpty && others == 1) {
      return 'Bạn và $topName';
    }
    return 'Bạn và $others người khác';
  }
  final name = topName;
  if (name == null || name.isEmpty) return '$likeCount';
  if (likeCount == 1) return name;
  return '$name và ${likeCount - 1} người khác';
}
