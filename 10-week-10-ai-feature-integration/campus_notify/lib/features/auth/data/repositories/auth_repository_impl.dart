import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required TokenStore tokenStore})
    // ignore: prefer_initializing_formals
    : _tokenStore = tokenStore;

  final TokenStore _tokenStore;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const LocalFailure('Email atau kata sandi tidak valid'),
        );
      }
      final model = AuthSessionModel(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
      );
      return (session: model.toEntity(), failure: null);
    } catch (e) {
      return (
        session: null,
        failure: LocalFailure('Gagal melakukan login: $e'),
      );
    }
  }

  @override
  Future<({String? token, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (refreshToken.isEmpty) {
        return (
          token: null,
          failure: const LocalFailure('Refresh token hilang'),
        );
      }
      final newAccess =
          'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
      return (token: newAccess, failure: null);
    } catch (e) {
      return (
        token: null,
        failure: LocalFailure('Gagal memperbarui token: $e'),
      );
    }
  }

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _tokenStore.save(access: access, refresh: refresh);
  }

  @override
  Future<String?> getStoredToken() async {
    return _tokenStore.readAccess();
  }

  @override
  Future<void> clearTokens() async {
    await _tokenStore.clear();
  }
}
