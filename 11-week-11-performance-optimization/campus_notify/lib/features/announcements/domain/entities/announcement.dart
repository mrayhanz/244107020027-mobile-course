class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.content = '',
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
}
