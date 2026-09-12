import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/pages/stats_page.dart';

void main() {
  group('StatsNotifier', () {
    test(
      'mengembalikan 3 item ketika request berhasil',
      () async {
        final notifier = StatsNotifier(
          failureChance: 0,
          delay: Duration.zero,
        );

        final result = await notifier.build();

        expect(result.length, 3);

        expect(
          result.any(
            (item) => item.label == 'Pengguna aktif',
          ),
          isTrue,
        );

        expect(
          result.any(
            (item) => item.label == 'Transaksi hari ini',
          ),
          isTrue,
        );

        expect(
          result.any(
            (item) => item.label == 'Retensi pengguna',
          ),
          isTrue,
        );
      },
    );

    test(
      'melempar exception ketika request gagal',
      () async {
        final notifier = StatsNotifier(
          failureChance: 1,
          delay: Duration.zero,
        );

        await expectLater(
          notifier.build(),
          throwsException,
        );
      },
    );
  });
}