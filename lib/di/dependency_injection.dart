import 'package:get_it/get_it.dart';

import 'package:taskee/features/todos/data/datasource/hive_todo_local_datasource.dart';
import 'package:taskee/features/todos/data/datasource/todo_local_datasource.dart';
import 'package:taskee/features/todos/data/repositorie/todo_repository_impl.dart';
import 'package:taskee/features/todos/domain/repositories/todo_repository.dart';
import 'package:taskee/features/todos/domain/usecases/add_todo.dart';
import 'package:taskee/features/todos/domain/usecases/delete_todo.dart';
import 'package:taskee/features/todos/domain/usecases/get_all_todos.dart';
import 'package:taskee/features/todos/domain/usecases/toggle_complete_todo.dart';
import 'package:taskee/features/todos/domain/usecases/undo_deleted_todo.dart';
import 'package:taskee/features/todos/domain/usecases/update_todo.dart';
import 'package:taskee/features/todos/presentation/bloc/todo_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  required HiveTodoLocalDataSource hiveTodoLocalDataSource,
}) async {
  // datasource
  getIt.registerLazySingleton<TodoLocalDataSource>(
    () => hiveTodoLocalDataSource,
  );

  // repository
  getIt.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(getIt()),
  );

  // usecases
  getIt.registerLazySingleton<GetAllTodos>(() => GetAllTodos(getIt()));
  getIt.registerLazySingleton<AddTodo>(() => AddTodo(getIt()));
  getIt.registerLazySingleton<UpdateTodo>(() => UpdateTodo(getIt()));
  getIt.registerLazySingleton<ToggleCompleteTodo>(
    () => ToggleCompleteTodo(getIt()),
  );
  getIt.registerLazySingleton<DeleteTodo>(() => DeleteTodo(getIt()));
  getIt.registerLazySingleton<UndoDeletedTodo>(() => UndoDeletedTodo(getIt()));

  // bloc
  getIt.registerFactory<TodoBloc>(
    () => TodoBloc(
      getAllTodos: getIt(),
      addTodo: getIt(),
      updateTodo: getIt(),
      toggleCompleteTodo: getIt(),
      deleteTodo: getIt(),
      undoDeletedTodo: getIt(),
    ),
  );
}
