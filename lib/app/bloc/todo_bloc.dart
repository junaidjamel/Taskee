import 'package:bloc/bloc.dart';
import 'package:taskee/app/bloc/todo_event.dart';
import 'package:taskee/app/bloc/todo_state.dart';
import 'package:taskee/app/model/todo_model.dart';
import 'package:taskee/app/vo/todo_vo.dart';
import 'package:taskee/domain/model/todo_domain.dart';
import '../../domain/usecase/add_todo_usecase.dart';
import '../../domain/usecase/delete_todo_usecase.dart';
import '../../domain/usecase/get_all_todo_usecase.dart';
import '../../domain/usecase/toggle_complete_todo_usecase.dart';
import '../../domain/usecase/undo_deleted_todo_usecase.dart';
import '../../domain/usecase/update_todo_usecase.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetAllTodoUseCase getAllTodoUseCase;
  final AddTodoUseCase addTodoUseCase;
  final UpdateTodoUseCase updateTodoUseCase;
  final ToggleCompleteTodoUseCase toggleCompleteTodoUseCase;
  final DeleteTodoUseCase deleteTodoUseCase;
  final UndoDeletedTodoUseCase undoDeletedTodoUseCase;
  TodoBloc({
    required this.getAllTodoUseCase,
    required this.addTodoUseCase,
    required this.updateTodoUseCase,
    required this.toggleCompleteTodoUseCase,
    required this.deleteTodoUseCase,
    required this.undoDeletedTodoUseCase,
  }) : super(TodoLoadingState()) {
    on<TodoStartedEvent>(_onStarted);
    on<TodoItemAddedEvent>(_onItemAdded);
    on<TodoItemUpdatedEvent>(_onItemUpdated);
    on<TodoItemToggleCompletedEvent>(_onItemToggleCompleted);
    on<TodoItemDeletedEvent>(_onItemDeleted);
    on<TodoItemUndoDeletedEvent>(_onItemUndoDeleted);
  }

  void _onStarted(TodoStartedEvent event, Emitter<TodoState> emit) async {
    emit(TodoLoadingState());
    try {
      var dataList = getAllTodoUseCase.execute();
      var todoVOList = dataList
          .map(
            (e) => TodoVO(
              id: e.id,
              title: e.title,
              description: e.description,
              isCompleted: e.isCompleted,
              dueAt: e.dueAt,
            ),
          )
          .toList();
      emit(TodoLoadedState(TodoModel(todoList: todoVOList)));
    } catch (e) {
      emit(const TodoErrorState());
    }
  }

  void _onItemAdded(TodoItemAddedEvent event, Emitter<TodoState> emit) async {
    emit(TodoLoadingState());
    try {
      var todoDomain = TodoDomain(
        event.todo.id,
        event.todo.title,
        event.todo.description,
        event.todo.isCompleted,
        dueAt: event.todo.dueAt,
      );
      addTodoUseCase.execute(todoDomain);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUpdated(
    TodoItemUpdatedEvent event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoadingState());
    try {
      var todoDomain = TodoDomain(
        event.todo.id,
        event.todo.title,
        event.todo.description,
        event.todo.isCompleted,
        dueAt: event.todo.dueAt,
      );
      updateTodoUseCase.execute(todoDomain);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemToggleCompleted(
    TodoItemToggleCompletedEvent event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoadingState());
    try {
      var todoDomain = TodoDomain(
        event.todo.id,
        event.todo.title,
        event.todo.description,
        event.todo.isCompleted,
        dueAt: event.todo.dueAt,
      );
      toggleCompleteTodoUseCase.execute(todoDomain);
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
      deleteTodoUseCase.execute(event.id);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }

  void _onItemUndoDeleted(
    TodoItemUndoDeletedEvent event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoadingState());
    try {
      var todoDomain = TodoDomain(
        event.todo.id,
        event.todo.title,
        event.todo.description,
        event.todo.isCompleted,
        dueAt: event.todo.dueAt,
      );
      undoDeletedTodoUseCase.execute(todoDomain);
      add(TodoStartedEvent());
    } catch (_) {
      emit(const TodoErrorState());
    }
  }
}
