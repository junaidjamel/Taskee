import 'package:taskee/features/notes/domain/repository/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;
  const DeleteNote(this.repository);

  void call(int id) => repository.deleteNote(id);
}
