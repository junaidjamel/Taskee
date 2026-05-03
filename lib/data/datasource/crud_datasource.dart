import '../entity/todo_data.dart';

abstract class CRUDDataSource {
  List<TodoData> getAllTodoList();
  void saveTodo(TodoData todo);
  void updateTodo(int id, TodoData todo);
  void deleteTodo(int id);
  void deleteAllTodoList();
}
