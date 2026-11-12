class NewsImage {
  const NewsImage({
    required this.id,
    required this.displayUrl,
    this.thumbUrl = '',
    this.url = '',
  });

  final String id;
  final String url;
  final String displayUrl;
  final String thumbUrl;
}
