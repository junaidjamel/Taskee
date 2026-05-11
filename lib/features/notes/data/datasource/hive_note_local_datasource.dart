import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/features/notes/data/datasource/note_local_datasource.dart';
import 'package:taskee/features/notes/data/model/note_hive_model.dart';

const String _noteBoxName = 'noteBox';
const String _latestIdBoxName = "noteLatestIdBox";
const String _latestIdName = "_latestId";

class HiveNoteLocalDatasource implements NoteLocalDatasource {
  late final Box<NoteHiveModel> _noteBox;
  late final Box<int> _lastIdBox;

  Future<void> initialize() async {
    Hive.registerAdapter(NoteHiveModelAdapter());

    _noteBox = await Hive.openBox<NoteHiveModel>(_noteBoxName);
    _lastIdBox = await Hive.openBox<int>(_latestIdBoxName);
  }

  @override
  List<NoteHiveModel> getAll() => _noteBox.values.toList();

  @override
  Future<void> save(NoteHiveModel note) async {
    final latestId = _lastIdBox.get(_latestIdName, defaultValue: 0) ?? 0;
    final newLatestId = latestId + 1;
    final entity = NoteHiveModel(
      id: newLatestId,
      note: note.note,
      createdAt: note.createdAt,
    );

    await _noteBox.put(entity.id, entity);
    await _lastIdBox.put(_latestIdName, newLatestId);
  }

  @override
  Future<void> update(int id, NoteHiveModel note) => _noteBox.put(id, note);
  @override
  Future<void> delete(int id) => _noteBox.delete(id);
}
