class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.content = '',
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
}
