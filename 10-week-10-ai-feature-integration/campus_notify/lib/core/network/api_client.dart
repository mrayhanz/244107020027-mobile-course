import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/token_store.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refresh = await store.readRefresh();
          if (refresh == null) return handler.next(e);
          try {
            final result = await auth.refresh(refresh);
            if (result.failure != null || result.token == null) {
              throw Exception(result.failure?.message ?? 'Refresh token gagal');
            }
            final renewed = result.token!;
            await store.save(access: renewed, refresh: refresh);
            final retry = await dio.fetch(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );
            return handler.resolve(retry);
          } catch (_) {
            await store.clear(); // refresh ikut mati -> paksa login ulang
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}
