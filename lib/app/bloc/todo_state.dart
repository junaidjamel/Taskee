import 'package:equatable/equatable.dart';

import '../model/todo_model.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoLoadingState extends TodoState {}

class TodoLoadedState extends TodoState {
   const TodoLoadedState(this.todoModel);

   final TodoModel todoModel;

   @override
   List<Object> get props => [todoModel];
}

class TodoErrorState extends TodoState {
  const TodoErrorState();
}
