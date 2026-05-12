import 'package:taskee/features/note/domain/entities/note.dart';

abstract class NoteRepository {
  List<Note> getNoteList();
  void addNote(Note note);
  void updateNote(Note note);
  void deleteNote(int id);
}
