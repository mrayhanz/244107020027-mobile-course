import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';

/// Fake repository: perilaku dikendalikan test, tanpa SQLite.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.fail = false});

  final bool fail;
  int addCalls = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: const <Note>[], failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    lastTitle = title;
    lastBody = body;

    if (fail) {
      return (
        note: null,
        failure: const LocalFailure('Gagal menyimpan catatan: db locked'),
      );
    }
    return (
      note: Note(title: title, body: body, updatedAt: DateTime(2026, 11, 10)),
      failure: null,
    );
  }
}

void main() {
  group('AddNote — aturan judul', () {
    test('menerima judul yang berisi teks', () async {
      final repo = FakeNoteRepository();

      // Arrange & Act
      final result = await AddNote(repo).call(title: 'Belajar Flutter');

      // Assert
      expect(result.failure, isNull);
      expect(result.note?.title, 'Belajar Flutter');
    });

    test('menolak judul kosong atau hanya spasi tanpa menyentuh repository',
        () async {
      final repo = FakeNoteRepository();
      final useCase = AddNote(repo);

      expect((await useCase(title: '')).failure, isA<LocalFailure>());
      expect((await useCase(title: '   ')).failure, isA<LocalFailure>());
      expect((await useCase(title: '\n\t ')).failure, isA<LocalFailure>());

      expect(repo.addCalls, 0, reason: 'Validasi harus gagal sebelum I/O');
    });

    test('memangkas spasi di awal dan akhir judul serta isi', () async {
      final repo = FakeNoteRepository();

      final result = await AddNote(repo).call(
        title: '  Tugas Mobile  ',
        body: '  laporan  ',
      );

      expect(result.note?.title, 'Tugas Mobile');
      expect(result.note?.body, 'laporan');
      expect(repo.lastTitle, 'Tugas Mobile');
    });
  });

  group('AddNote — dependensi repository', () {
    test('meneruskan failure repository apa adanya', () async {
      final result = await AddNote(
        FakeNoteRepository(fail: true),
      ).call(title: 'Judul valid');

      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, 'Gagal menyimpan catatan: db locked');
      expect(result.note, isNull);
    });

    test('meneruskan note hasil simpan', () async {
      final repo = FakeNoteRepository();

      final result = await AddNote(repo).call(title: 'Catatan baru');

      expect(repo.addCalls, 1);
      expect(result.note?.title, 'Catatan baru');
    });
  });
}
