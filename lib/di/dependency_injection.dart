import 'package:get_it/get_it.dart';

import 'package:taskee/features/note/data/datasource/hive_note_local_datasource.dart';
import 'package:taskee/features/note/data/datasource/note_local_datasource.dart';
import 'package:taskee/features/note/data/repository/note_repository_impl.dart';
import 'package:taskee/features/note/domain/repository/note_repository.dart';
import 'package:taskee/features/note/domain/usecase/add_note.dart';
import 'package:taskee/features/note/domain/usecase/delete_note.dart';
import 'package:taskee/features/note/domain/usecase/get_all_notes.dart';
import 'package:taskee/features/note/domain/usecase/update_note.dart';
import 'package:taskee/features/note/presentation/bloc/note_bloc.dart';
import 'package:taskee/features/todo/data/datasource/hive_todo_local_datasource.dart';
import 'package:taskee/features/todo/data/datasource/todo_local_datasource.dart';
import 'package:taskee/features/todo/data/repositorie/todo_repository_impl.dart';
import 'package:taskee/features/todo/domain/repositories/todo_repository.dart';
import 'package:taskee/features/todo/domain/usecases/add_todo.dart';
import 'package:taskee/features/todo/domain/usecases/delete_todo.dart';
import 'package:taskee/features/todo/domain/usecases/get_all_todos.dart';
import 'package:taskee/features/todo/domain/usecases/toggle_complete_todo.dart';
import 'package:taskee/features/todo/domain/usecases/undo_deleted_todo.dart';
import 'package:taskee/features/todo/domain/usecases/update_todo.dart';
import 'package:taskee/features/todo/presentation/bloc/todo_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  required HiveTodoLocalDataSource hiveTodoLocalDataSource,
  required HiveNoteLocalDatasource hiveNoteLocalDatasource,
}) async {
  // ── Todo ──────────────────────────────────────────────
  getIt.registerLazySingleton<TodoLocalDataSource>(
    () => hiveTodoLocalDataSource,
  );
  getIt.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<GetAllTodos>(() => GetAllTodos(getIt()));
  getIt.registerLazySingleton<AddTodo>(() => AddTodo(getIt()));
  getIt.registerLazySingleton<UpdateTodo>(() => UpdateTodo(getIt()));
  getIt.registerLazySingleton<ToggleCompleteTodo>(
    () => ToggleCompleteTodo(getIt()),
  );
  getIt.registerLazySingleton<DeleteTodo>(() => DeleteTodo(getIt()));
  getIt.registerLazySingleton<UndoDeletedTodo>(() => UndoDeletedTodo(getIt()));
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

  // ── Note ──────────────────────────────────────────────
  getIt.registerLazySingleton<NoteLocalDatasource>(
    () => hiveNoteLocalDatasource,
  );
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<GetAllNotes>(() => GetAllNotes(getIt()));
  getIt.registerLazySingleton<AddNote>(() => AddNote(getIt()));
  getIt.registerLazySingleton<UpdateNote>(() => UpdateNote(getIt()));
  getIt.registerLazySingleton<DeleteNote>(() => DeleteNote(getIt()));
  getIt.registerFactory<NoteBloc>(
    () => NoteBloc(
      getAllNotes: getIt(),
      addNote: getIt(),
      updateNote: getIt(),
      deleteNote: getIt(),
    ),
  );
}
