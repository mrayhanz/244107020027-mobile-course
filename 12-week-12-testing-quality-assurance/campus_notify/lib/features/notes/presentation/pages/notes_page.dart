import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

/// Halaman Catatan yang telah dioptimasi performanya:
/// 1. [NotesPage] statis const: scaffold tidak ikut rebuild saat query/data berganti.
/// 2. [NotesSearchHeader] menggunakan `select((q) => q.isNotEmpty)` agar tidak
///    rebuild pada setiap ketikan huruf (hanya rebuild saat tombol clear muncul/hilang).
/// 3. Controller di-dispose dengan benar saat state dimusnahkan (anti-leak).
/// 4. Setiap baris catatan dibungkus [RepaintBoundary] untuk memisahkan paint pass.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Kampus')),
      body: const Column(
        children: [
          NotesSearchHeader(),
          Expanded(child: _NotesBody()),
        ],
      ),
      floatingActionButton: const _AddNoteFab(),
    );
  }
}

class NotesSearchHeader extends ConsumerStatefulWidget {
  const NotesSearchHeader({super.key});

  @override
  ConsumerState<NotesSearchHeader> createState() => _NotesSearchHeaderState();
}

class _NotesSearchHeaderState extends ConsumerState<NotesSearchHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    // Wajib: dispose controller untuk menghindari memory leak.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optimasi Riverpod select: hanya rebuild jika flag isNotEmpty berubah,
    // bukan setiap karakter yang diketikkan pengguna.
    final hasQuery = ref.watch(
      noteSearchQueryProvider.select((q) => q.isNotEmpty),
    );

    // Sinkronisasi teks jika state query di-reset dari luar (mis. clear)
    ref.listen<String>(noteSearchQueryProvider, (prev, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        key: const Key('notes_search_field'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasQuery
              ? IconButton(
                  key: const Key('notes_search_clear_button'),
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(noteSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (val) {
          ref.read(noteSearchQueryProvider.notifier).setQuery(val);
        },
      ),
    );
  }
}

class _NotesBody extends ConsumerWidget {
  const _NotesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredNotesProvider);
    final query = ref.watch(noteSearchQueryProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _NotesErrorView(
        error: e.toString(),
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? _NotesEmptyState(query: query)
          : _NotesListView(notes: notes),
    );
  }
}

class _NotesListView extends StatelessWidget {
  const _NotesListView({required this.notes});
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = notes[index];
        // Isolasi layer raster per tile untuk menghemat overhead repaint
        return RepaintBoundary(
          child: ListTile(
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: note.body.isNotEmpty ? Text(note.body) : null,
            leading: const CircleAvatar(
              child: Icon(Icons.note_outlined, size: 20),
            ),
          ),
        );
      },
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearching = query.trim().isNotEmpty;
    final message = isSearching
        ? 'Tidak ada catatan yang cocok dengan "$query".'
        : 'Belum ada catatan.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.notes_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesErrorView extends StatelessWidget {
  const _NotesErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _AddNoteFab extends ConsumerWidget {
  const _AddNoteFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      key: const Key('add_note_button'),
      onPressed: () async {
        final saved = await showDialog<bool>(
          context: context,
          builder: (_) => const _AddNoteDialog(),
        );
        if (saved == true && context.mounted) {
          ref.invalidate(notesProvider);
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Catatan'),
    );
  }
}

class _AddNoteDialog extends ConsumerStatefulWidget {
  const _AddNoteDialog();

  @override
  ConsumerState<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Judul catatan wajib diisi.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final result = await ref
        .read(addNoteProvider)
        .call(title: title, body: _bodyController.text.trim());

    if (!mounted) return;

    if (result.failure != null) {
      setState(() {
        _isSaving = false;
        _error = result.failure!.message;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('add_note_title'),
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Judul',
              hintText: 'Contoh: Tugas Mobile Week 11',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('add_note_body'),
            controller: _bodyController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Isi (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('add_note_save'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
