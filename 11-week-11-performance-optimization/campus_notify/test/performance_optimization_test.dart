import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/performance/debouncer.dart';
import 'package:campus_notify/core/performance/stale_cache.dart';
import 'package:campus_notify/core/network/retry_interceptor.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcements_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> announcements, Failure? failure, bool hasMore})>
  getAnnouncements({int page = 1}) async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: null,
        hasMore: false,
      );
    }
    return (announcements: items, failure: null, hasMore: false);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    return (announcement: items.isNotEmpty ? items.first : null, failure: null);
  }
}

void main() {
  group('1. Debouncer Performance Tests', () {
    test('Debouncer menunda eksekusi callback sesuai durasi', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var count = 0;

      debouncer.run(() => count++);
      debouncer.run(() => count++);
      debouncer.run(() => count++);

      expect(count, 0, reason: 'Belum boleh jalan sebelum delay habis');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(count, 1, reason: 'Hanya panggilan terakhir yang dieksekusi');

      debouncer.dispose();
    });

    test('Debouncer cancel membatalkan eksekusi yang tertunda', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var ran = false;

      debouncer.run(() => ran = true);
      debouncer.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(ran, isFalse);
      debouncer.dispose();
    });
  });

  group('2. StaleCache & Offline-First Repository Tests', () {
    test(
      'StaleCache membaca, menulis, dan melacak status stale sesuai TTL',
      () async {
        final cache = StaleCache<String, String>(
          ttl: const Duration(milliseconds: 40),
        );

        cache.write('key1', 'val1');
        expect(cache.read('key1'), 'val1');
        expect(cache.isStale('key1'), isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(cache.isStale('key1'), isTrue, reason: 'Harus ditandai stale');
        expect(
          cache.read('key1'),
          'val1',
          reason: 'Nilai lama tetap ada sebagai fallback',
        );

        cache.clear();
        expect(cache.read('key1'), isNull);
      },
    );

    test(
      'AnnouncementRepositoryImpl mendukung pagination & cache hit',
      () async {
        final repo = AnnouncementRepositoryImpl();

        // Page 1: load dari repository
        final res1 = await repo.getAnnouncements(page: 1);
        expect(res1.failure, isNull);
        expect(res1.announcements.length, AnnouncementRepositoryImpl.pageSize);
        expect(res1.hasMore, isTrue);

        // Hit kedua: harus datang dari cache
        final resCached = await repo.getAnnouncements(page: 1);
        expect(resCached.announcements.first.id, res1.announcements.first.id);

        // Page melebihi kapasitas
        final resOver = await repo.getAnnouncements(page: 10);
        expect(resOver.hasMore, isFalse);
        expect(resOver.announcements, isEmpty);
      },
    );
  });

  group('3. Dio RetryInterceptor Configuration Tests', () {
    test('RetryInterceptor mendeteksi header retry attempt', () {
      final dio = Dio();
      final interceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 2,
        retryDelays: const [Duration(milliseconds: 10)],
      );

      expect(interceptor.maxRetries, 2);
      expect(interceptor.retryDelays.length, 1);
    });
  });

  group('4. Widget Tree Rebuild & Repaint Isolation Tests', () {
    testWidgets('NotesPage membungkus tiap tile dengan RepaintBoundary', (
      tester,
    ) async {
      final sample = [
        Note(
          id: 1,
          title: 'Optimasi Mobile',
          body: 'Gunakan RepaintBoundary',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesProvider.overrideWith((ref) => Future.value(sample)),
          ],
          child: const MaterialApp(home: NotesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Optimasi Mobile'), findsOneWidget);
    });

    testWidgets(
      'AnnouncementsPage me-render ListView.builder & kartu pengumuman',
      (tester) async {
        final mockAnnouncements = [
          Announcement(
            id: '1',
            title: 'UTS Pemrograman Mobile',
            content: 'Dilaksanakan serentak di Lab Komputer',
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              announcementRepositoryProvider.overrideWithValue(
                FakeAnnouncementRepository(items: mockAnnouncements),
              ),
            ],
            child: const MaterialApp(home: AnnouncementsPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('announcements_list')), findsOneWidget);
        expect(find.text('UTS Pemrograman Mobile'), findsOneWidget);
        expect(find.byType(RepaintBoundary), findsWidgets);
      },
    );
    testWidgets('NotesPage menyediakan FAB tambah catatan dan dialog input', (
      tester,
    ) async {
      final sample = <Note>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesProvider.overrideWith((ref) => Future.value(sample)),
          ],
          child: const MaterialApp(home: NotesPage()),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('add_note_button'));
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Tambah Catatan'), findsOneWidget);
      expect(find.byKey(const Key('add_note_title')), findsOneWidget);
      expect(find.byKey(const Key('add_note_body')), findsOneWidget);
      expect(find.byKey(const Key('add_note_save')), findsOneWidget);
    });
  });
}
