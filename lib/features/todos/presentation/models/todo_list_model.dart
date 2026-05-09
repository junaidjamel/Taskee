import 'package:equatable/equatable.dart';

import '../../domain/entities/todo.dart';

class TodoListModel extends Equatable {
  const TodoListModel({required this.todoList});

  final List<Todo> todoList;

  @override
  List<Object> get props => [todoList];
}

