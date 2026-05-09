import 'package:flutter/material.dart';
import 'package:taskee/features/widget/app_gradient.dart';

import '../../../domain/entities/todo.dart';
import 'widgets/update_todo_form.dart';

class UpdateTodoScreen extends StatefulWidget {
  final Todo todo;

  const UpdateTodoScreen({super.key, required this.todo});

  @override
  UpdateTodoScreenState createState() => UpdateTodoScreenState();
}

class UpdateTodoScreenState extends State<UpdateTodoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(child: UpdateTodoForm(todo: widget.todo)),
    );
  }
}
