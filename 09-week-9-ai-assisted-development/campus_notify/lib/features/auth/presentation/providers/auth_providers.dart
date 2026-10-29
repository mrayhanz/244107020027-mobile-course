import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(tokenStore: ref.watch(tokenStoreProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final token = await repo.getStoredToken();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(loginUseCaseProvider);
      final repo = ref.read(authRepositoryProvider);
      final result = await useCase(email: email, password: password);
      if (result.failure != null) {
        throw Exception(result.failure!.message);
      }
      final session = result.session!;
      await repo.saveTokens(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).clearTokens();
    ref.invalidateSelf();
  }
}
