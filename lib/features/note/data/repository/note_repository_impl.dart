import 'package:taskee/features/note/data/datasource/note_local_datasource.dart';
import 'package:taskee/features/note/data/mappers/note_mapper.dart';
import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/domain/repository/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDatasource localDatasource;
  NoteRepositoryImpl(this.localDatasource);
  @override
  void addNote(Note note) {
    localDatasource.save(note.toHiveModel());
  }

  @override
  List<Note> getNoteList() {
    return localDatasource.getAll().map((e) => e.toDomain()).toList();
  }

  @override
  void updateNote(Note note) {
    localDatasource.update(note.id, note.toHiveModel());
  }

  @override
  void deleteNote(int id) => localDatasource.delete(id);
}
