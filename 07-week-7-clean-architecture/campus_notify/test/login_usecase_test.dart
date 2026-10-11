import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login_usecase.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.fail = false});

  final bool fail;
  String? savedAccess;
  String? savedRefresh;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (fail) {
      return (
        session: null,
        failure: const NetworkFailure('Koneksi terputus (simulasi)'),
      );
    }
    return (
      session: AuthSession(
        access: 'mock-access-$email',
        refresh: 'mock-refresh-$email',
      ),
      failure: null,
    );
  }

  @override
  Future<({String? token, Failure? failure})> refresh(String refreshToken) async {
    return (token: 'refreshed-token', failure: null);
  }

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    savedAccess = access;
    savedRefresh = refresh;
  }

  @override
  Future<String?> getStoredToken() async => savedAccess;

  @override
  Future<void> clearTokens() async {
    savedAccess = null;
    savedRefresh = null;
  }
}

void main() {
  test('LoginUseCase gagal jika email tidak valid atau password < 6', () async {
    final repo = FakeAuthRepository();
    final useCase = LoginUseCase(repo);

    final resInvalidEmail = await useCase(email: 'invalidemail', password: 'password123');
    expect(resInvalidEmail.failure, isA<LocalFailure>());
    expect(resInvalidEmail.session, isNull);

    final resShortPass = await useCase(email: 'test@example.com', password: '123');
    expect(resShortPass.failure, isA<LocalFailure>());
    expect(resShortPass.session, isNull);
  });

  test('LoginUseCase sukses meneruskan sesi dari repository', () async {
    final repo = FakeAuthRepository();
    final useCase = LoginUseCase(repo);

    final res = await useCase(email: 'user@example.com', password: 'password123');
    expect(res.failure, isNull);
    expect(res.session, isNotNull);
    expect(res.session!.access, 'mock-access-user@example.com');
  });

  test('LoginUseCase meneruskan failure dari repository ketika jaringan error', () async {
    final repo = FakeAuthRepository(fail: true);
    final useCase = LoginUseCase(repo);

    final res = await useCase(email: 'user@example.com', password: 'password123');
    expect(res.failure, isA<NetworkFailure>());
    expect(res.session, isNull);
  });
}
