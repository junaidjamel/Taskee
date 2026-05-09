import '../models/todo_hive_model.dart';

abstract class TodoLocalDataSource {
  List<TodoHiveModel> getAll();
  Future<void> save(TodoHiveModel todo);
  Future<void> update(int id, TodoHiveModel todo);
  Future<void> delete(int id);
}

