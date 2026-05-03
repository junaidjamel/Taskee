import 'package:taskee/data/entity/todo_data.dart';

import '../../domain/model/todo_domain.dart';
import '../../domain/repository/todo_repository.dart';
import '../datasource/crud_datasource.dart';

class TodoRepositoryImpl extends TodoRepository {
  final CRUDDataSource dataSource;
  TodoRepositoryImpl(this.dataSource);

  @override
  void addTodo(TodoDomain todo) {
    return dataSource.saveTodo(
      TodoData(todo.id, todo.title, todo.description, todo.isCompleted),
    );
  }

  @override
  void toggleCompleteTodo(TodoDomain todo) {
    return dataSource.updateTodo(
      todo.id,
      TodoData(todo.id, todo.title, todo.description, !todo.isCompleted),
    );
  }

  @override
  void deleteTodo(int id) {
    return dataSource.deleteTodo(id);
  }

  @override
  List<TodoDomain> getTodoList() {
    return dataSource
        .getAllTodoList()
        .map((e) => TodoDomain(e.id, e.title, e.description, e.isCompleted))
        .toList();
  }

  @override
  void updateTodo(TodoDomain todo) async {
    return dataSource.updateTodo(
      todo.id,
      TodoData(todo.id, todo.title, todo.description, todo.isCompleted),
    );
  }
}
