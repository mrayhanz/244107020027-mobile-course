import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'repositories/note_repository.dart';

// ---------------------------------------------------------
// 1. Toggle Simulasi Offline
// ---------------------------------------------------------

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) {
    state = value;
  }
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

// ---------------------------------------------------------
// 2. Logika Sinkronisasi Catatan Kotor
// ---------------------------------------------------------

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repo.markAllSynced();

  return dirtyCount;
}

// ---------------------------------------------------------
// 3. Provider NoteRepository
// ---------------------------------------------------------

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes();
});