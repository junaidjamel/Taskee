import '../entities/todo.dart';

abstract class TodoRepository {
  List<Todo> getTodoList();
  void addTodo(Todo todo);
  void toggleCompleteTodo(Todo todo);
  void updateTodo(Todo todo);
  void deleteTodo(int id);
}

