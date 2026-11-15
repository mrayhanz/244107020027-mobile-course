import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class _EndToEndNoteRepository implements NoteRepository {
  final List<Note> _notes = [];
  var _nextId = 1;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.unmodifiable(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: _nextId++,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, note);
    return (note: note, failure: null);
  }
}

void main() {
  testWidgets('alur utama: pengguna menambah catatan lalu mencarinya', (
    tester,
  ) async {
    final repository = _EndToEndNoteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kondisi awal: kosong.
    expect(find.text('Belum ada catatan.'), findsOneWidget);

    // 2. Buka dialog tambah catatan.
    await tester.tap(find.byKey(const Key('add_note_button')));
    await tester.pumpAndSettle();

    // 3. Masukkan judul & isi catatan.
    await tester.enterText(
      find.byKey(const Key('add_note_title')),
      'Tugas Mobile Week 12',
    );
    await tester.enterText(
      find.byKey(const Key('add_note_body')),
      'Testing & Quality Assurance',
    );
    await tester.tap(find.byKey(const Key('add_note_save')));
    await tester.pumpAndSettle();

    // 4. Catatan tampil di list.
    expect(find.text('Tugas Mobile Week 12'), findsOneWidget);
    expect(find.text('Belum ada catatan.'), findsNothing);
    expect(repository._notes, hasLength(1));

    // 5. Cari catatan berdasarkan judul.
    await tester.enterText(
      find.byKey(const Key('notes_search_field')),
      'Week 12',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tugas Mobile Week 12'), findsOneWidget);

    // 6. Query tidak cocok menampilkan empty state.
    await tester.enterText(
      find.byKey(const Key('notes_search_field')),
      'Basis Data',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Tidak ada catatan yang cocok dengan "Basis Data".'),
      findsOneWidget,
    );
    expect(find.text('Tugas Mobile Week 12'), findsNothing);

    // 7. Tombol clear mengembalikan daftar utuh.
    await tester.tap(find.byKey(const Key('notes_search_clear_button')));
    await tester.pumpAndSettle();
    expect(find.text('Tugas Mobile Week 12'), findsOneWidget);
  });
}
