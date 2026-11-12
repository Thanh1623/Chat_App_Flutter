class NewsAuthor {
  const NewsAuthor({required this.id, required this.name, this.avatarUrl = ''});

  final String id;
  final String name;
  final String avatarUrl;
}

class NewsSource {
  const NewsSource({required this.name, required this.url});

  final String name;
  final String url;
}

class NewsCoverImage {
  const NewsCoverImage({
    required this.id,
    required this.displayUrl,
    this.thumbUrl = '',
  });

  final String id;
  final String displayUrl;
  final String thumbUrl;
}

class NewsCard {
  const NewsCard({
    required this.id,
    required this.title,
    required this.excerpt,
    this.cover,
    this.author,
    this.source,
    required this.publishedAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String title;
  final String excerpt;
  final NewsCoverImage? cover;
  final NewsAuthor? author;
  final NewsSource? source;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final int likeCount;
  final int commentCount;
}
