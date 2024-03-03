class NewsArticle {
  final String title;
  final String description;
  final String? articleText;

  NewsArticle({
    required this.title,
    required this.description,
    this.articleText = "loremIpsum",
  });
}
