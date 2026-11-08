import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/debouncer.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';

// Data layer: panggil openNotesDb yang diimpor dari layer data
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final searchNotesProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});

// Notifier untuk state query pencarian (Riverpod 3 Notifier).
// Query di-debounce 250 ms agar filter list tidak dieksekusi pada setiap
// ketikan karakter (mengurangi rebuild + alokasi list sementara).
class NoteSearchQueryNotifier extends Notifier<String> {
  final Debouncer _debouncer = Debouncer();

  @override
  String build() {
    ref.onDispose(_debouncer.dispose);
    return '';
  }

  void setQuery(String query) {
    _debouncer.run(() => state = query);
  }

  void clear() {
    _debouncer.cancel();
    state = '';
  }
}

final noteSearchQueryProvider =
    NotifierProvider<NoteSearchQueryNotifier, String>(
      NoteSearchQueryNotifier.new,
    );

// State filtered notes yang memadukan raw data dan SearchNotes use case
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(noteSearchQueryProvider);
  final searchUseCase = ref.watch(searchNotesProvider);

  return notesAsync.whenData((notes) => searchUseCase(notes, query));
});
