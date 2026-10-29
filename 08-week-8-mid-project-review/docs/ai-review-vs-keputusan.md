# AI Review vs Keputusan Final

## 1. AI Prompt
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data), Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran) + alasan + usulan potongan kode perbaikan.

## 2. Output Awal AI (Ringkasan 5 Temuan)

### Temuan 1: GoRouter RefreshListenable Tidak Terhubung ke Riverpod State
- **Level**: Blocker
- **Alasan**: `router` didefinisikan statis di luar Riverpod scope pada `lib/main.dart` dan hanya membaca state sekali. Ketika user login atau logout, `GoRouter` tidak menerima notifikasi pembaruan router (tidak ada `refreshListenable`), sehingga redirect auth tidak otomatis berjalan.
- **Usulan Perbaikan**:
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.notifier).stream),
    redirect: (context, state) {
      final loggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingLogin) return '/login';
      if (loggedIn && goingLogin) return '/';
      return null;
    },
    // routes...
  );
});
```

### Temuan 2: Duplikasi dan Salah Letak `add_notes.dart` di Fitur Announcements
- **Level**: Saran
- **Alasan**: Ditemukan file `lib/features/announcements/domain/usecases/add_notes.dart` yang berisi logic validasi note di dalam domain announcements. Fitur notes sudah punya use case tersendiri di `lib/features/notes/domain/usecases/add_note.dart`. File ini dead code yang melanggar screaming architecture.
- **Usulan Perbaikan**:
Hapus file liar `lib/features/announcements/domain/usecases/add_notes.dart` dan rapikan namespace fitur.

### Temuan 3: Usecase CRUD `AddNote` Anemic / Passthrough
- **Level**: Saran
- **Alasan**: `AddNote` usecase hanya meneruskan input mentah ke `_repository.addNote(...)` tanpa validasi domain. Validasi `title.isNotEmpty` justru bocor di layer presentation dialog (`notes_page.dart:40`).
- **Usulan Perbaikan**:
```dart
class AddNote {
  const AddNote(this._repository);
  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    if (title.trim().isEmpty) {
      return Future.value((
        note: null,
        failure: const LocalFailure('Judul tidak boleh kosong'),
      ));
    }
    return _repository.addNote(title: title.trim(), body: body);
  }
}
```

### Temuan 4: Tanggung Jawab Penyimpanan Token Bocor di Presentation `AuthNotifier`
- **Level**: Blocker
- **Alasan**: `AuthNotifier.login` memanggil `useCase(...)` lalu memanggil `repo.saveTokens(...)` secara terpisah di layer presentation (`auth_providers.dart:42`). Persistensi token setelah auth berhasil adalah tanggung jawab data/domain auth flow, bukan UI state notifier.
- **Usulan Perbaikan**:
Pindahkan pemanggilan penyimpanan token ke dalam repository implementation saat login HTTP berhasil, sehingga UI hanya memicu satu aksi bisnis.
```dart
// Di AuthNotifier cukup satu aksi:
Future<void> login(String email, String password) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final useCase = ref.read(loginUseCaseProvider);
    final result = await useCase(email: email, password: password);
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return true;
  });
}
```

### Temuan 5: Saran Mengganti Record Result Pattern Menjadi `dartz` / `Either<Failure, T>`
- **Level**: Saran
- **Alasan AI**: Pola Dart Record `({T? data, Failure? failure})` dianggap kurang fungsional dibanding `Either<L, R>` dari library eksternal.
- **Usulan Perbaikan AI**:
Tambahkan dependensi `dartz` atau `fpdart` untuk return type use case dan repository:
```dart
Future<Either<Failure, List<Note>>> fetchNotes();
```

---

## 3. Tabel Verifikasi & Keputusan Final

| No | Temuan AI | Level | Bukti / Verifikasi | Status | Alasan & Keputusan Final |
|---|---|---|---|---|---|
| 1 | `GoRouter` tidak reaktif terhadap auth state | Blocker | Terbukti di `lib/main.dart:19`, instance router statis tanpa listener | **Diterima** | Diterapkan `routerProvider` agar reaktif terhadap perubahan auth state. |
| 2 | File `add_notes.dart` nyasar di domain announcements | Saran | Terbukti via `grep` dan file tree di `lib/features/announcements/...` | **Diterima** | Dihapus karena dead code dan melanggar prinsip screaming architecture. |
| 3 | Usecase `AddNote` anemic (passthrough) | Saran | Terbukti di `notes_page.dart:40`, validasi judul kosong bocor di widget UI | **Diterima** | Validasi aturan bisnis judul dipindah ke domain usecase `AddNote`. |
| 4 | Token save dipanggil manual di Presentation | Blocker | Terbukti di `auth_providers.dart:42`, notifier koordinasi dua call repo | **Diterima** | Tanggung jawab penyimpanan token dipindah ke layer data/repo implementation. |
| 5 | Ganti Dart Record ke package `dartz` (`Either`) | Saran | Evaluasi fitur Dart 3 vs overhead dependensi | **Ditolak** | Dart 3 Record native, type-safe, dan efisien. Menambah library `dartz` melanggar KISS/YAGNI. |

---

## 4. Bukti Eksekusi (Test / Analyze)
- `flutter analyze` : Clean (No issues found)
- `flutter test` : Passed (All unit & widget tests green)
