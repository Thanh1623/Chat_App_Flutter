import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';

class NewsPostPage {
  const NewsPostPage({required this.items, this.nextCursor});

  final List<NewsFeedItem> items;
  final String? nextCursor;
}
