import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatsItem {
  const StatsItem({
    required this.label,
    required this.value,
    required this.change,
  });

  final String label;
  final String value;
  final String change;
}

class StatsNotifier extends AsyncNotifier<List<StatsItem>> {
  StatsNotifier({
    this.failureChance = 0.3,
    this.delay = const Duration(seconds: 2),
  });

  final double failureChance;
  final Duration delay;

  @override
  Future<List<StatsItem>> build() async {
    await Future.delayed(delay);

    final shouldFail =
        Random().nextDouble() < failureChance;

    if (shouldFail) {
      throw Exception(
        'Gagal memuat statistik. Silakan coba lagi.',
      );
    }

    return const [
      StatsItem(
        label: 'Pengguna aktif',
        value: '24.5K',
        change: '+12.4% dari minggu lalu',
      ),
      StatsItem(
        label: 'Transaksi hari ini',
        value: '1,248',
        change: '+8.1% dari hari kemarin',
      ),
      StatsItem(
        label: 'Retensi pengguna',
        value: '87%',
        change: '+2.3% dari bulan lalu',
      ),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatsItem>>(
  StatsNotifier.new,
);

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),

      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan saat memuat data statistik.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(statsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),

        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(item.label),
                subtitle: Text(item.change),
                trailing: Text(
                  item.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          },
        ),
      ),

      // NavigationBar untuk berpindah halaman.
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}