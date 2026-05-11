import 'package:taskee/features/notes/domain/entities/note.dart';
import 'package:taskee/features/notes/domain/repository/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;
  const UpdateNote(this.repository);

  void call(Note note) => repository.updateNote(note);
}
