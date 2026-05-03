import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/cache/database/entity/todo.dart';
import '../../data/datasource/crud_datasource.dart';
import '../../data/entity/todo_data.dart';

const String _todoBoxName = 'todoBox';
const String _latestIdBoxName = "latestIdBox";
const String _latestIdName = "_latestId";

class AppDatabase extends CRUDDataSource {
  AppDatabase._constructor();

  static final AppDatabase _instance = AppDatabase._constructor();

  factory AppDatabase() => _instance;

  late Box _todoBox;
  late Box _lastIdBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TodoEntityAdapter());
    _todoBox = await Hive.openBox(_todoBoxName);
    _lastIdBox = await Hive.openBox(_latestIdBoxName);
  }

  void close() {
    // Closes all Hive boxes
    Hive.close();
  }

  @override
  void saveTodo(TodoData todo) async {
    try {
      int latestId = _lastIdBox.get(_latestIdName, defaultValue: 0);
      int newLatestId = latestId + 1;
      var todoEntity = TodoEntity(
        id: newLatestId,
        title: todo.title,
        description: todo.description,
        isCompleted: todo.isCompleted,
      );
      await _todoBox.put(todoEntity.id, todoEntity);
      await _lastIdBox.put(_latestIdName, newLatestId);
    } catch (error) {
      print(error);
    }
  }

  @override
  void updateTodo(int id, TodoData todo) async {
    try {
      await _todoBox.put(
        todo.id,
        TodoEntity(
          id: todo.id,
          title: todo.title,
          description: todo.description,
          isCompleted: todo.isCompleted,
        ),
      );
    } catch (error) {
      print(error);
    }
  }

  @override
  void deleteTodo(int id) async {
    try {
      await _todoBox.delete(id);
    } catch (error) {
      print(error);
    }
  }

  @override
  void deleteAllTodoList() async {
    try {
      await _todoBox.clear();
    } catch (error) {
      print(error);
    }
  }

  @override
  List<TodoData> getAllTodoList() {
    return _todoBox.values
        .map((e) => TodoData(e.id, e.title, e.description, e.isCompleted))
        .toList();
  }
}
