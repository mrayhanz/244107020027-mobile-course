import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets(
    'App starts successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      expect(
        find.text('Offline Notes'),
        findsOneWidget,
      );
    },
  );
}