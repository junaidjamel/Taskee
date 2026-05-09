import 'package:flutter/material.dart';

import 'package:taskee/app/extension/context_extension.dart';

import 'package:taskee/features/todos/presentation/pages/add/add_todo_screen.dart';
import 'package:taskee/features/todos/presentation/pages/home/widget/task_widget.dart';
import 'package:taskee/features/todos/presentation/pages/home/widget/user_info.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.gotTo(const AddTodoScreen()),

        child: const Icon(Icons.add),
      ),
      body: AppGradient(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [UserInfoWidget(), TaskWidget()],
        ),
      ),
    );
  }
}
