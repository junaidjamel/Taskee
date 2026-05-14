import 'package:bloc/bloc.dart';
import 'package:taskee/features/todo/domain/usecases/cancel_task_notification.dart';
import 'package:taskee/features/todo/domain/usecases/schedule_task_notification.dart';

import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_all_todos.dart';
import '../../domain/usecases/toggle_complete_todo.dart';
import '../../domain/usecases/undo_deleted_todo.dart';
import '../../domain/usecases/update_todo.dart';
import '../../domain/models/todo_list_model.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetAllTodos getAllTodos;
  final AddTodo addTodo;
  final UpdateTodo updateTodo;
  final ToggleCompleteTodo toggleCompleteTodo;
  final DeleteTodo deleteTodo;
  final UndoDeletedTodo undoDeletedTodo;
  final ScheduleTaskNotification scheduleTaskNotification;
  final CancelTaskNotification cancelTaskNotification;

  TodoBloc({
    required this.getAllTodos,
    required this.addTodo,
    required this.updateTodo,
    required this.toggleCompleteTodo,
    required this.deleteTodo,
    required this.undoDeletedTodo,
    required this.scheduleTaskNotification,
    required this.cancelTaskNotification,
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

  void _onItemAdded(TodoItemAddedEvent event, Emitter<TodoState> emit) async {
    try {
      addTodo(event.todo);
      await scheduleTaskNotification(event.todo);
      final dataList = getAllTodos();
      emit(TodoLoadedState(TodoListModel(todoList: dataList)));
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUpdated(
    TodoItemUpdatedEvent event,
    Emitter<TodoState> emit,
  ) async {
    try {
      updateTodo(event.todo);
      try {
        await cancelTaskNotification(event.todo.id);
      } catch (_) {}
      await scheduleTaskNotification(event.todo);
      final dataList = getAllTodos();
      emit(TodoLoadedState(TodoListModel(todoList: dataList)));
    } catch (e, stackTrace) {
      print('UPDATE ERROR: $e');
      print('STACK: $stackTrace');
      emit(const TodoErrorState());
    }
  }

  void _onItemToggleCompleted(
    TodoItemToggleCompletedEvent event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoadingState());
    try {
      toggleCompleteTodo(event.todo);
      //  cancel notification if task is completed
      if (!event.todo.isCompleted) {
        await cancelTaskNotification(event.todo.id);
      }
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemDeleted(
    TodoItemDeletedEvent event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoadingState());
    try {
      deleteTodo(event.id);
      await cancelTaskNotification(event.id);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUndoDeleted(
    TodoItemUndoDeletedEvent event,
    Emitter<TodoState> emit,
  ) async {
    try {
      undoDeletedTodo(event.todo);
      await scheduleTaskNotification(event.todo);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }
}
