import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class ToggleCompleteTodo {
  final TodoRepository repository;
  ToggleCompleteTodo(this.repository);

  void call(Todo todo) => repository.toggleCompleteTodo(todo);
}

