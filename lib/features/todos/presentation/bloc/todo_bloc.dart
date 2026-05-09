import 'package:bloc/bloc.dart';

import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_all_todos.dart';
import '../../domain/usecases/toggle_complete_todo.dart';
import '../../domain/usecases/undo_deleted_todo.dart';
import '../../domain/usecases/update_todo.dart';
import '../models/todo_list_model.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetAllTodos getAllTodos;
  final AddTodo addTodo;
  final UpdateTodo updateTodo;
  final ToggleCompleteTodo toggleCompleteTodo;
  final DeleteTodo deleteTodo;
  final UndoDeletedTodo undoDeletedTodo;

  TodoBloc({
    required this.getAllTodos,
    required this.addTodo,
    required this.updateTodo,
    required this.toggleCompleteTodo,
    required this.deleteTodo,
    required this.undoDeletedTodo,
  }) : super(TodoLoadingState()) {
    on<TodoStartedEvent>(_onStarted);
    on<TodoItemAddedEvent>(_onItemAdded);
    on<TodoItemUpdatedEvent>(_onItemUpdated);
    on<TodoItemToggleCompletedEvent>(_onItemToggleCompleted);
    on<TodoItemDeletedEvent>(_onItemDeleted);
    on<TodoItemUndoDeletedEvent>(_onItemUndoDeleted);
  }

  void _onStarted(TodoStartedEvent event, Emitter<TodoState> emit) {
    emit(TodoLoadingState());
    try {
      final dataList = getAllTodos();
      emit(TodoLoadedState(TodoListModel(todoList: dataList)));
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemAdded(TodoItemAddedEvent event, Emitter<TodoState> emit) {
    emit(TodoLoadingState());
    try {
      addTodo(event.todo);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUpdated(TodoItemUpdatedEvent event, Emitter<TodoState> emit) {
    emit(TodoLoadingState());
    try {
      updateTodo(event.todo);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemToggleCompleted(
    TodoItemToggleCompletedEvent event,
    Emitter<TodoState> emit,
  ) {
    emit(TodoLoadingState());
    try {
      toggleCompleteTodo(event.todo);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemDeleted(TodoItemDeletedEvent event, Emitter<TodoState> emit) {
    emit(TodoLoadingState());
    try {
      deleteTodo(event.id);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUndoDeleted(
    TodoItemUndoDeletedEvent event,
    Emitter<TodoState> emit,
  ) {
    emit(TodoLoadingState());
    try {
      undoDeletedTodo(event.todo);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }
}
