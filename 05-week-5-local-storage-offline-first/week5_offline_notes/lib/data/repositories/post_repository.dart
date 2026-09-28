import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  // ---------------------------------------------------------
  // 1. Membaca data dari tabel SQLite (Cache)
  // ---------------------------------------------------------
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    if (rows.isEmpty) return [];

    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String);
      return Post.fromJson(payload as Map<String, dynamic>);
    }).toList();
  }

  // ---------------------------------------------------------
  // 2. Menimpa (save) data dari internet ke SQLite
  // ---------------------------------------------------------
  Future<void> _savePostsToCache(List<dynamic> data) async {
    final db = await _openDb();
    final batch = db.batch();
    batch.delete('cached_posts'); // Hapus cache lama

    for (var item in data) {
      batch.insert('cached_posts', {
        'id': item['id'],
        'payload': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------
  // 3. Mengambil data dari API di latar belakang
  // ---------------------------------------------------------
  Future<void> refreshPostsInBackground() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/posts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        await _savePostsToCache(data);
      }
    } catch (_) {
      // Abaikan error jika gagal (misal karena benar-benar offline)
    }
  }

  // ---------------------------------------------------------
  // 4. Logika Utama: Cache-First Read
  // ---------------------------------------------------------
  Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async {
    // 1. Segera kembalikan cache agar UI tidak blank saat offline.
    final cached = await readCachedPosts();

    // 2. Di background: fetch HTTP -> simpan ke cached_posts
    if (!forceOffline) {
      refreshPostsInBackground(); // sengaja tidak di-await
    }

    return cached;
  }
}