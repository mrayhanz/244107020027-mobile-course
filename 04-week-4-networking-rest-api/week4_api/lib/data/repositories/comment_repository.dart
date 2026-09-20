import 'package:dio/dio.dart';

import '../models/comment.dart';

class CommentRepository {
  // Repository hanya bertanggung jawab untuk mengambil data dari API.
  // Dengan cara ini, UI/provider tidak perlu tahu detail endpoint atau Dio.
  CommentRepository(this._dio);

  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    // Endpoint JSONPlaceholder: GET /comments?postId={id}
    // Timeout 10 detik dibuat di BaseOptions maupun per request agar lebih jelas.
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];

    // Hanya data yang benar-benar map akan diubah ke model.
    // Ini mencegah crash bila API mengirim item yang bukan objek map.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
