import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AiService {
  Future<String> ask(String question);
  Future<void> saveApiKey(String key);
  Future<bool> hasApiKey();
}

class GeminiAiService implements AiService {
  GeminiAiService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _keyName = 'gemini_api_key';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3.1-flash-lite:generateContent';

  @override
  Future<String> ask(String question) async {
    final key = await _storage.read(key: _keyName);
    if (key == null || key.isEmpty) {
      throw const AiException('API key belum diatur.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'key': key},
        data: {
          'system_instruction': {
            'parts': [
              {
                'text':
                    'Kamu asisten kampus ramah. Jawab dalam Bahasa '
                    'Indonesia, maksimal 2 kalimat. Jangan meminta atau '
                    'mengungkap data pribadi.',
              },
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': question},
              ],
            },
          ],
        },
      );
      final candidates = response.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiException('AI tidak memberikan jawaban.');
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts == null || parts.isEmpty
          ? null
          : parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const AiException('AI tidak memberikan jawaban.');
      }
      return text.trim();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final serverMsg = error.response?.data?['error']?['message'] as String?;
      if (status == 429) {
        throw const AiException('Batas permintaan tercapai (Rate Limit 429).');
      }
      if (status == 400 || status == 403) {
        throw AiException(
          'API key tidak valid atau expired ($status): ${serverMsg ?? "Periksa key di Google AI Studio"}',
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw const AiException(
          'Gagal terhubung ke Google Gemini. Cek koneksi internet.',
        );
      }
      throw AiException(
        serverMsg != null
            ? 'Error API ($status): $serverMsg'
            : 'Gagal terhubung ke Gemini (${error.message ?? status}).',
      );
    }
  }

  @override
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _keyName, value: key.trim());
  }

  @override
  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _keyName);
    return key != null && key.isNotEmpty;
  }
}

class AiException implements Exception {
  const AiException(this.message);
  final String message;

  @override
  String toString() => message;
}
