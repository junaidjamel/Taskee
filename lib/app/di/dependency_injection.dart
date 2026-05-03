import 'package:get_it/get_it.dart';
import 'package:taskee/app/bloc/todo_bloc.dart';
import 'package:taskee/data/repository_impl/todo_repository_impl.dart';
import 'package:taskee/domain/repository/todo_repository.dart';
import 'package:taskee/domain/usecase/undo_deleted_todo_usecase.dart';
import '../../data/datasource/crud_datasource.dart';
import '../../domain/usecase/add_todo_usecase.dart';
import '../../domain/usecase/delete_todo_usecase.dart';
import '../../domain/usecase/get_all_todo_usecase.dart';
import '../../domain/usecase/toggle_complete_todo_usecase.dart';
import '../../domain/usecase/update_todo_usecase.dart';

GetIt getIt = GetIt.instance;

Future configureDependencies(CRUDDataSource database) async {
  //datasource
  getIt.registerLazySingleton<CRUDDataSource>(() => database);

  //repository
  getIt.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(getIt()),
  );

  //use case
  getIt.registerLazySingleton<GetAllTodoUseCase>(
    () => GetAllTodoUseCase(getIt()),
  );
  getIt.registerLazySingleton<AddTodoUseCase>(() => AddTodoUseCase(getIt()));
  getIt.registerLazySingleton<UpdateTodoUseCase>(
    () => UpdateTodoUseCase(getIt()),
  );
  getIt.registerLazySingleton<ToggleCompleteTodoUseCase>(
    () => ToggleCompleteTodoUseCase(getIt()),
  );
  getIt.registerLazySingleton<DeleteTodoUseCase>(
    () => DeleteTodoUseCase(getIt()),
  );
  getIt.registerLazySingleton<UndoDeletedTodoUseCase>(
    () => UndoDeletedTodoUseCase(getIt()),
  );

  //bloc
  getIt.registerFactory<TodoBloc>(
    () => TodoBloc(
      getAllTodoUseCase: getIt(),
      addTodoUseCase: getIt(),
      updateTodoUseCase: getIt(),
      toggleCompleteTodoUseCase: getIt(),
      deleteTodoUseCase: getIt(),
      undoDeletedTodoUseCase: getIt(),
    ),
  );
}
