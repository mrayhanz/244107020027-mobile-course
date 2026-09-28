import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/providers.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({
    this.items = const [],
    this.throwError = false,
  }) : super(
          openDb: () => throw UnimplementedError(),
        );

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) {
      throw Exception('db locked (simulasi)');
    }

    return items;
  }

  @override
  Future<int> countDirty() {
    return Future.value(
      items.where((n) => n.dirty).length,
    );
  }
}

void main() {
  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({
      'title': 'Belanja',
    });

    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty bertahan pada serialisasi', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );

    final restored = Note.fromMap(
      note.toMap(),
    );

    expect(restored.dirty, isTrue);
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [
              Note(
                title: 'Tes',
                updatedAt: DateTime.now(),
              ),
            ],
          ),
        ),
      ],
    );

    final subscription = container.listen(
      notesProvider,
      (_, _) {},
      fireImmediately: true,
    );

    try {
      for (var i = 0; i < 100; i++) {
        final state = container.read(notesProvider);

        if (state.hasValue) {
          break;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 10),
        );
      }

      final state = container.read(notesProvider);

      expect(state.hasValue, isTrue);
      expect(state.value!.length, 1);
      expect(state.value!.first.title, 'Tes');
    } finally {
      subscription.close();
      container.dispose();
    }
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            throwError: true,
          ),
        ),
      ],
    );

    final subscription = container.listen(
      notesProvider,
      (_, _) {},
      fireImmediately: true,
    );

    try {
      for (var i = 0; i < 100; i++) {
        final state = container.read(notesProvider);

        if (state.hasError) {
          break;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 10),
        );
      }

      final state = container.read(notesProvider);

      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    } finally {
      subscription.close();
      container.dispose();
    }
  });
}