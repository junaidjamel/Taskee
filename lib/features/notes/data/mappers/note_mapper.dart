import 'package:taskee/features/notes/data/model/note_hive_model.dart';
import 'package:taskee/features/notes/domain/entities/note.dart';

extension NoteHiveModelToDomain on NoteHiveModel {
  Note toDomain() {
    return Note(id: id, note: note, createdAt: DateTime.now());
  }
}

extension NoteDomainToHiveModel on Note {
  NoteHiveModel toHiveModel() {
    return NoteHiveModel(id: id, note: note, createdAt: createdAt);
  }
}
