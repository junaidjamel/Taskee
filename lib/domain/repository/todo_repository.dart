import '../model/todo_domain.dart';

abstract class TodoRepository {
  List<TodoDomain> getTodoList();
  void addTodo(TodoDomain todo);
  void toggleCompleteTodo(TodoDomain todo);
  void updateTodo(TodoDomain todo);
  void deleteTodo(int id);
}
