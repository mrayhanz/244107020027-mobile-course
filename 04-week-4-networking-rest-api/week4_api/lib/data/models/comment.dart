class Comment {
  // Model domain untuk satu data komentar dari JSONPlaceholder.
  // Semua field dibuat final agar data bersifat immutable dan mudah dipakai di UI.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  // fromJson aman null karena API terkadang mengirim field kosong atau tidak ada.
  // Jika key tidak ditemukan, kita berikan nilai default agar model tetap stabil.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  // toJson dipakai bila kita butuh kirim object ke API atau debug.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
