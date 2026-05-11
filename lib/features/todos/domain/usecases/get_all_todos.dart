import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetAllTodos {
  final TodoRepository repository;
  const GetAllTodos(this.repository);

  List<Todo> call() => repository.getTodoList();
}
