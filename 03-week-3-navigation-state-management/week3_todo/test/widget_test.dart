import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_todo/main.dart';
import 'package:week3_todo/pages/stats_page.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(
      find.text('Belum ada tugas'),
      findsOneWidget,
    );

    await tester.tap(
      find.byIcon(Icons.add),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(TextField),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'Kerjakan PR minggu 3',
    );

    await tester.tap(
      find.text('Tambah'),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Kerjakan PR minggu 3'),
      findsOneWidget,
    );
  });

  testWidgets(
    'berpindah ke halaman statistik',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statsProvider.overrideWith(
              () => StatsNotifier(
                failureChance: 0,
                delay: Duration.zero,
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Statistik'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Statistik'),
        findsWidgets,
      );
    },
  );
}