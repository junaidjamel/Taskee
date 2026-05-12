import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/domain/repository/note_repository.dart';

class AddNote {
  final NoteRepository repository;
  AddNote(this.repository);

  void call(Note note) => repository.addNote(note);
}
