import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'setting_page.dart';

// Provider untuk waktu terakhir dibuka dari SharedPreferences
final lastOpenedProvider = FutureProvider.autoDispose<String?>((ref) async {
  final prefs = ref.watch(prefsRepositoryProvider);

  final lastOpened = await prefs.getLastOpened();

  await prefs.markOpenedNow();

  return lastOpened;
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Tombol Dark Mode
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),

          // Tombol Sync
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);

              await syncNotes(repo);

              ref.invalidate(notesProvider);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinkronisasi selesai!'),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Banner Terakhir Dibuka
          Container(
            width: double.infinity,
            color: Colors.blue.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Text(
              lastOpenedAsync.when(
                data: (date) => date != null
                    ? 'Terakhir dibuka: $date'
                    : 'Terakhir dibuka: Belum pernah',
                loading: () => 'Memuat...',
                error: (_, _) => 'Gagal memuat',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          // Daftar Catatan
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              error: (err, _) => Center(
                child: Text('Error: $err'),
              ),

              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Belum ada catatan.'),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    return ListTile(
                      title: Text(note.title),

                      subtitle: Text(
                        '${note.body}\nDiperbarui: ${note.updatedAt}',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      isThreeLine: true,

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Sync
                          Icon(
                            note.dirty
                                ? Icons.cloud_off
                                : Icons.cloud_done,
                            color: note.dirty
                                ? Colors.orange
                                : Colors.green,
                          ),

                          const SizedBox(width: 8),

                          // Tombol Hapus
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              final repo =
                                  ref.read(noteRepositoryProvider);

                              await repo.deleteNote(note.id!);

                              ref.invalidate(notesProvider);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Tombol Tambah Catatan
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final repo = ref.read(noteRepositoryProvider);

          await repo.addNote(
            title: 'Catatan Baru ${DateTime.now().second}',
            body: 'Isi catatan offline-first',
          );

          ref.invalidate(notesProvider);
        },
      ),
    );
  }
}