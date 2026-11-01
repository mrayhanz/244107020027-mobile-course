import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? token, Failure? failure})> refresh(String refreshToken);

  Future<void> saveTokens({required String access, required String refresh});

  Future<String?> getStoredToken();

  Future<void> clearTokens();
}
