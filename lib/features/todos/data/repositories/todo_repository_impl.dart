import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';
import '../mappers/todo_mapper.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;
  TodoRepositoryImpl(this.localDataSource);

  @override
  void addTodo(Todo todo) {
    localDataSource.save(todo.toHiveModel());
  }

  @override
  void toggleCompleteTodo(Todo todo) {
    localDataSource.update(
      todo.id,
      Todo(
        id: todo.id,
        title: todo.title,
        description: todo.description,
        isCompleted: !todo.isCompleted,
        dueAt: todo.dueAt,
      ).toHiveModel(),
    );
  }

  @override
  void deleteTodo(int id) {
    localDataSource.delete(id);
  }

  @override
  List<Todo> getTodoList() {
    return localDataSource.getAll().map((e) => e.toDomain()).toList();
  }

  @override
  void updateTodo(Todo todo) {
    localDataSource.update(todo.id, todo.toHiveModel());
  }
}

