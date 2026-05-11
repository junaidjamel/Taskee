import 'package:taskee/features/notes/domain/entities/note.dart';
import 'package:taskee/features/notes/domain/repository/note_repository.dart';

class GetAllNotes {
  final NoteRepository repository;
  const GetAllNotes(this.repository);

  List<Note> call() => repository.getNoteList();
}
