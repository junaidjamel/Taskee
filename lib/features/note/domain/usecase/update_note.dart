import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/domain/repository/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;
  const UpdateNote(this.repository);

  void call(Note note) => repository.updateNote(note);
}
