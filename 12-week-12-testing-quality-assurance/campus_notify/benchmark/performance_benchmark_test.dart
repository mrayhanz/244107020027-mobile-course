import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

/// Benchmark lokal untuk memverifikasi optimasi (bukan DevTools).
/// Jalankan: flutter test benchmark/performance_benchmark_test.dart
void main() {
  testWidgets('lazy ListView.builder vs eager ListView(children)', (
    tester,
  ) async {
    const itemCount = 1000;
    var eagerBuilt = 0;
    var lazyBuilt = 0;

    final eagerChildren = List<Widget>.generate(itemCount, (i) {
      eagerBuilt++;
      return Text('Item $i');
    });

    await tester.pumpWidget(
      MaterialApp(home: ListView(children: eagerChildren)),
    );
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            lazyBuilt++;
            return Text('Item $index');
          },
        ),
      ),
    );
    await tester.pump();

    // ignore: avoid_print
    print('BENCHMARK eager_build=$eagerBuilt lazy_build=$lazyBuilt');
    expect(lazyBuilt, lessThan(eagerBuilt));
  });

  testWidgets('debounce mengurangi update query saat mengetik cepat', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var updates = 0;
    container.listen<String>(noteSearchQueryProvider, (previous, next) {
      updates++;
    });

    for (var i = 0; i < 50; i++) {
      container.read(noteSearchQueryProvider.notifier).setQuery('query-$i');
    }

    await tester.pump(const Duration(milliseconds: 320));

    // ignore: avoid_print
    print('BENCHMARK query_updates_without_debounce=50 actual=$updates');
    expect(updates, 1);
  });

  test('cache hit lebih cepat dari fetch pertama', () async {
    final repo = AnnouncementRepositoryImpl();

    final firstWatch = Stopwatch()..start();
    await repo.getAnnouncements(page: 1);
    firstWatch.stop();

    final cachedWatch = Stopwatch()..start();
    await repo.getAnnouncements(page: 1);
    cachedWatch.stop();

    // ignore: avoid_print
    print(
      'BENCHMARK first_fetch_ms=${firstWatch.elapsedMilliseconds} '
      'cached_fetch_ms=${cachedWatch.elapsedMilliseconds}',
    );
    expect(cachedWatch.elapsedMilliseconds, lessThan(50));
  });
}
