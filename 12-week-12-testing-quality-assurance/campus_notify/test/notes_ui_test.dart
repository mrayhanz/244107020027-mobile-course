import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

Note _note(String title) =>
    Note(title: title, updatedAt: DateTime(2026, 11, 10));

Widget _app(
  Widget child, {
  List<dynamic> overrides = const [],
  Duration? Function(int, Object)? retry,
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    retry: retry,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('NotesPage — state tampilan', () {
    testWidgets('menampilkan indikator loading selama data dimuat', (
      tester,
    ) async {
      final pending = Completer<List<Note>>();

      await tester.pumpWidget(
        _app(
          const NotesPage(),
          overrides: [notesProvider.overrideWith((ref) => pending.future)],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });

    testWidgets('menampilkan error dan pulih setelah tombol Coba Lagi', (
      tester,
    ) async {
      var calls = 0;

      await tester.pumpWidget(
        _app(
          const NotesPage(),
          retry: (retryCount, error) => null,
          overrides: [
            notesProvider.overrideWith((ref) async {
              calls++;
              if (calls == 1) throw Exception('database sibuk');
              return [_note('Pulih dari error')];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('database sibuk'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Pulih dari error'), findsOneWidget);
      expect(calls, 2);
    });

    testWidgets('menampilkan pesan berbeda saat hasil pencarian kosong', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const NotesPage(),
          overrides: [
            notesProvider.overrideWith(
              (ref) async => [_note('Algoritma dan Struktur Data')],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'jaringan',
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Tidak ada catatan yang cocok dengan "jaringan".'),
        findsOneWidget,
      );
    });
  });

  group('NotesPage — interaksi pencarian', () {
    testWidgets('query menyaring daftar catatan (case-insensitive)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const NotesPage(),
          overrides: [
            notesProvider.overrideWith(
              (ref) async => [
                _note('Algoritma dan Struktur Data'),
                _note('Jaringan Komputer'),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'jaringan',
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Jaringan Komputer'), findsOneWidget);
      expect(find.text('Algoritma dan Struktur Data'), findsNothing);
    });

    testWidgets('tombol clear mengosongkan query dan memulihkan daftar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const NotesPage(),
          overrides: [
            notesProvider.overrideWith(
              (ref) async => [_note('Algoritma dan Struktur Data')],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'algo',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('notes_search_clear_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('notes_search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Algoritma dan Struktur Data'), findsOneWidget);
      expect(find.byKey(const Key('notes_search_clear_button')), findsNothing);
    });
  });
}
