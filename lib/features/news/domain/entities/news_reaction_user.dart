import 'package:chat_app/features/news/domain/entities/news_card.dart';

class NewsReactionUser {
  const NewsReactionUser({required this.kind, required this.user});

  final String kind;
  final NewsAuthor user;
}
