import 'package:chat_app/features/news/data/models/news_models.dart';
import 'package:chat_app/features/news/domain/entities/news_card.dart';
import 'package:chat_app/features/news/domain/entities/news_reaction_user.dart';

class NewsReactionUserModel {
  NewsReactionUserModel.fromJson(Map<String, dynamic> json)
    : kind = json['kind']?.toString() ?? 'like',
      user = _parseUser(json['user']);

  final String kind;
  final NewsAuthor user;

  // _parseUser là hàm private, chỉ dùng trong class NewsReactionUserModel dùng để parse user từ json
  static NewsAuthor _parseUser(dynamic raw) {
    return NewsCardModel.parseAuthor(raw) ??
        const NewsAuthor(id: '', name: 'Người dùng');
  }

  NewsReactionUser toEntity() => NewsReactionUser(kind: kind, user: user);
}

/// parseNewsReactionUsers là hàm public, dùng để parse list news reaction users từ json
List<NewsReactionUser> parseNewsReactionUsers(dynamic raw) {
  if (raw is! Map) return const [];
  final items = raw['items'];
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map(
        (e) =>
            NewsReactionUserModel.fromJson(Map<String, dynamic>.from(e))
                .toEntity(),
      )
      .toList();
}
