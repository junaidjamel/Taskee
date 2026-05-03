import 'package:taskee/domain/model/todo_domain.dart';
import 'package:taskee/domain/repository/todo_repository.dart';

class GetAllTodoUseCase {
  final TodoRepository repository;
  GetAllTodoUseCase(this.repository);

  List<TodoDomain> execute() {
    return repository.getTodoList();
  }
}
