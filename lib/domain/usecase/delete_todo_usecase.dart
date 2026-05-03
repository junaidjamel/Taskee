import 'package:taskee/domain/repository/todo_repository.dart';

class DeleteTodoUseCase {
  final TodoRepository repository;
  DeleteTodoUseCase(this.repository);

  void execute(int id) {
    return repository.deleteTodo(id);
  }
}
