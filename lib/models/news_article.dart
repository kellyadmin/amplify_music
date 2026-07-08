class NewsArticle {
  final String title;
  final String link;
  final String imageUrl;
  final String source;
  final String pubDate;
  final String content;
  final String aiSummary;

  NewsArticle({
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.source,
    required this.pubDate,
    required this.content,
    this.aiSummary = '',
  });

  NewsArticle copyWith({
    String? title,
    String? link,
    String? imageUrl,
    String? source,
    String? pubDate,
    String? content,
    String? aiSummary,
  }) {
    return NewsArticle(
      title: title ?? this.title,
      link: link ?? this.link,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      pubDate: pubDate ?? this.pubDate,
      content: content ?? this.content,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      title: map['title'] ?? 'No Title',
      link: map['link'] ?? '',
      imageUrl: map['image_url'] ?? map['thumbnail'] ??
          map['enclosure']?['link'] ??
          _extractImageUrlFromHtml(map['content'] ?? '') ??
          'https://placehold.co/250x100/282828/FFFFFF?text=No+Image',
      source: map['source'] ?? map['author'] ?? 'Unknown Source',
      pubDate: map['pub_date'] ?? map['pubDate'] ?? '',
      content: map['content'] ?? 'No content available.',
      aiSummary: map['ai_summary'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'image_url': imageUrl,
      'source': source,
      'pub_date': pubDate,
      'content': content,
      'ai_summary': aiSummary,
    };
  }
}

String? _extractImageUrlFromHtml(String? htmlContent) {
  if (htmlContent == null || htmlContent.isEmpty) return null;
  final RegExp regex = RegExp(
    r'<img[^>]+src="([^">]+)"',
    multiLine: true,
    caseSensitive: false,
  );
  final match = regex.firstMatch(htmlContent);
  return match?.group(1);
}
