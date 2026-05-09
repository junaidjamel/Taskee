import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class UpdateTodo {
  final TodoRepository repository;
  UpdateTodo(this.repository);

  void call(Todo todo) => repository.updateTodo(todo);
}

