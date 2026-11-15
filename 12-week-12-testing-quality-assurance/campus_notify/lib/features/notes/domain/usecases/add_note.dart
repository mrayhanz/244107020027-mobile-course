import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  const AddNote(this._repository);
  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    // Aturan bisnis dipisah dari UI supaya bisa diuji tanpa widget.
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Future.value((
        note: null,
        failure: const LocalFailure('Judul catatan wajib diisi.'),
      ));
    }
    return _repository.addNote(title: trimmedTitle, body: body.trim());
  }
}
