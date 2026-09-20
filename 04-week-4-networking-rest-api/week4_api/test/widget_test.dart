import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/main.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/data/models/post.dart';

void main() {
  testWidgets(
    'App starts successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pagedPostsProvider.overrideWith(
              () => FakePagedPostsNotifier(),
            ),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pump();

      expect(find.text('Posts Paged'), findsOneWidget);
      expect(find.text('Test Post'), findsOneWidget);
    },
  );
}

class FakePagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() {
    return PagedPostsState(
      items: const [
        Post(
          userId: 1,
          id: 1,
          title: 'Test Post',
          body: 'Test body',
        ),
      ],
      page: 1,
      hasMore: false,
    );
  }
}