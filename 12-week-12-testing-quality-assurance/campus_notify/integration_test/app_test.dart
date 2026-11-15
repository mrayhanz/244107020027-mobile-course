import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

/// Repository in-memory: alur nyata NotesPage -> AddNote -> provider -> UI,
/// hanya lapisan penyimpanan yang diganti agar tidak butuh SQLite/Firebase.
class InMemoryNoteRepository implements NoteRepository {
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pengguna menambah catatan lalu mencarinya', (tester) async {
    final repository = InMemoryNoteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Kondisi awal: daftar kosong.
    expect(find.text('Belum ada catatan.'), findsOneWidget);

    // Tambah catatan lewat dialog.
    await tester.tap(find.byKey(const Key('add_note_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add_note_title')),
      'Tugas Mobile Week 12',
    );
    await tester.enterText(
      find.byKey(const Key('add_note_body')),
      'Menulis pengujian unit, widget, dan integrasi',
    );
    await tester.tap(find.byKey(const Key('add_note_save')));
    await tester.pumpAndSettle();

    expect(find.text('Tugas Mobile Week 12'), findsOneWidget);
    expect(find.text('Belum ada catatan.'), findsNothing);

    // Cari catatan yang baru dibuat.
    await tester.enterText(
      find.byKey(const Key('notes_search_field')),
      'week 12',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tugas Mobile Week 12'), findsOneWidget);

    // Query yang tidak cocok menampilkan empty state pencarian.
    await tester.enterText(
      find.byKey(const Key('notes_search_field')),
      'kalkulus',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Tidak ada catatan yang cocok dengan "kalkulus".'),
      findsOneWidget,
    );
  });
}
