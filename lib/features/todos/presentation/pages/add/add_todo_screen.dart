import 'package:flutter/material.dart';

import 'widgets/add_todo_form.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  AddTodoScreenState createState() => AddTodoScreenState();
}

class AddTodoScreenState extends State<AddTodoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Add Todo')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: AddTodoForm(),
      ),
    );
  }
}

