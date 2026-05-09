import 'package:equatable/equatable.dart';

import '../../domain/entities/todo.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoStartedEvent extends TodoEvent {}

class TodoItemAddedEvent extends TodoEvent {
  const TodoItemAddedEvent(this.todo);
  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemUpdatedEvent extends TodoEvent {
  const TodoItemUpdatedEvent(this.todo);
  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemToggleCompletedEvent extends TodoEvent {
  const TodoItemToggleCompletedEvent(this.todo);
  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

class TodoItemDeletedEvent extends TodoEvent {
  const TodoItemDeletedEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class TodoItemUndoDeletedEvent extends TodoEvent {
  const TodoItemUndoDeletedEvent(this.todo);
  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

