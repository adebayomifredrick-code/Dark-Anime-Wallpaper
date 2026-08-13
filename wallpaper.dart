class Wallpaper {
  final String id;
  final String title;
  final String category;
  final String url;
  final String? thumbnailUrl;
  final String author;
  final int views;

  Wallpaper({
    required this.id,
    required this.title,
    required this.category,
    required this.url,
    this.thumbnailUrl,
    this.author = 'Unknown',
    this.views = 0,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Dark Anime Wallpaper',
      category: json['category'] ?? 'General',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['url'],
      author: json['author'] ?? 'Anime Artist',
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'author': author,
      'views': views,
    };
  }
}
