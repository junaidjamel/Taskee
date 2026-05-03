import 'package:equatable/equatable.dart';
import 'package:taskee/app/vo/todo_vo.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoStartedEvent extends TodoEvent {
  @override
  List<Object?> get props => [];
}

class TodoItemAddedEvent extends TodoEvent {
  const TodoItemAddedEvent(this.todo);

  final TodoVO todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemUpdatedEvent extends TodoEvent {
  const TodoItemUpdatedEvent(this.todo);

  final TodoVO todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemToggleCompletedEvent extends TodoEvent {
  const TodoItemToggleCompletedEvent(this.todo);

  final TodoVO todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemDeletedEvent extends TodoEvent {
  const TodoItemDeletedEvent(this.id);

  final int id;

  @override
  List<Object?> get props => [];
}

class TodoItemUndoDeletedEvent extends TodoEvent {
  const TodoItemUndoDeletedEvent(this.todo);

  final TodoVO todo;

  @override
  List<Object?> get props => [];
}
