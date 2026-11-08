import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class _MemoryNoteRepository implements NoteRepository {
  final List<Note> notes = [];
  var nextId = 1;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.unmodifiable(notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: nextId++,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    notes.insert(0, note);
    return (note: note, failure: null);
  }
}

void main() {
  testWidgets('tambah catatan menyimpan data dan refresh daftar', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada catatan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_note_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('add_note_title')),
      'Tugas Mobile Week 11',
    );
    await tester.enterText(
      find.byKey(const Key('add_note_body')),
      'Selesaikan laporan optimasi performa',
    );

    await tester.tap(find.byKey(const Key('add_note_save')));
    await tester.pumpAndSettle();

    expect(repository.notes, hasLength(1));
    expect(repository.notes.first.title, 'Tugas Mobile Week 11');
    expect(find.text('Tugas Mobile Week 11'), findsOneWidget);
    expect(find.text('Belum ada catatan.'), findsNothing);
  });

  testWidgets('judul kosong ditolak tanpa menyimpan', (tester) async {
    final repository = _MemoryNoteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_note_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_note_save')));
    await tester.pumpAndSettle();

    expect(repository.notes, isEmpty);
    expect(find.text('Judul catatan wajib diisi.'), findsOneWidget);
  });
}
