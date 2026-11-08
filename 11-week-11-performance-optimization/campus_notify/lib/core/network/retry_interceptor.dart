import 'dart:async';

import 'package:dio/dio.dart';

/// Interceptor Dio untuk mencoba ulang (retry) request yang gagal karena transient network error.
/// Mencegah request berulang tak terkontrol dan memberi jeda backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  });

  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  static const String retryHeader = 'X-Retry-Count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final currentAttempt = (extra[retryHeader] as int? ?? 0);

    final shouldRetry = currentAttempt < maxRetries && _isRetryable(err);

    if (!shouldRetry) {
      return handler.next(err);
    }

    final nextAttempt = currentAttempt + 1;
    final delayIndex = (nextAttempt - 1).clamp(0, retryDelays.length - 1);
    final delay = retryDelays[delayIndex];

    await Future<void>.delayed(delay);

    final options = Options(
      method: err.requestOptions.method,
      headers: Map<String, dynamic>.from(err.requestOptions.headers),
      responseType: err.requestOptions.responseType,
      contentType: err.requestOptions.contentType,
      validateStatus: err.requestOptions.validateStatus,
      receiveTimeout: err.requestOptions.receiveTimeout,
      sendTimeout: err.requestOptions.sendTimeout,
      extra: Map<String, dynamic>.from(err.requestOptions.extra)
        ..[retryHeader] = nextAttempt,
    );

    try {
      final response = await dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: options,
      );
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        return code != null && (code >= 500 && code <= 599);
      default:
        return false;
    }
  }
}
