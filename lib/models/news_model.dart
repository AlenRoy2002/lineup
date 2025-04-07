class NewsArticle {
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? source;

  NewsArticle({
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      source: json['source'] != null ? json['source']['name'] : null,
    );
  }
}
