import 'package:taskee/features/note/data/model/note_hive_model.dart';

abstract class NoteLocalDatasource {
  List<NoteHiveModel> getAll();
  Future<void> save(NoteHiveModel note);
  Future<void> update(int id, NoteHiveModel note);
  Future<void> delete(int id);
}
