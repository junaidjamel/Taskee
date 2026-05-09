import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_hive_model.dart';
import 'todo_local_datasource.dart';

const String _todoBoxName = 'todoBox';
const String _latestIdBoxName = "latestIdBox";
const String _latestIdName = "_latestId";

class HiveTodoLocalDataSource implements TodoLocalDataSource {
  late final Box<TodoHiveModel> _todoBox;
  late final Box<int> _lastIdBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TodoHiveModelAdapter());

    _todoBox = await Hive.openBox<TodoHiveModel>(_todoBoxName);
    _lastIdBox = await Hive.openBox<int>(_latestIdBoxName);
  }

  @override
  List<TodoHiveModel> getAll() => _todoBox.values.toList();

  @override
  Future<void> save(TodoHiveModel todo) async {
    final latestId = _lastIdBox.get(_latestIdName, defaultValue: 0) ?? 0;
    final newLatestId = latestId + 1;
    final entity = TodoHiveModel(
      id: newLatestId,
      title: todo.title,
      isCompleted: todo.isCompleted,
      dueAt: todo.dueAt,
    );
    await _todoBox.put(entity.id, entity);
    await _lastIdBox.put(_latestIdName, newLatestId);
  }

  @override
  Future<void> update(int id, TodoHiveModel todo) => _todoBox.put(id, todo);

  @override
  Future<void> delete(int id) => _todoBox.delete(id);
}
