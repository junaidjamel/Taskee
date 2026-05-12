import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/domain/repository/note_repository.dart';

class GetAllNotes {
  final NoteRepository repository;
  const GetAllNotes(this.repository);

  List<Note> call() => repository.getNoteList();
}
