import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class UndoDeletedTodo {
  final TodoRepository repository;
  UndoDeletedTodo(this.repository);

  void call(Todo todo) => repository.addTodo(todo);
}
