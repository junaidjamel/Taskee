import 'package:flutter/material.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Update Todo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: UpdateTodoForm(todo: widget.todo),
      ),
    );
  }
}

