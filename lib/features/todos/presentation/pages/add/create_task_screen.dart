import 'package:flutter/material.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/features/widget/app_gradient.dart';

import 'widgets/create_task_widget.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  CreateTaskScreenState createState() => CreateTaskScreenState();
}

class CreateTaskScreenState extends State<CreateTaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: AppGradient(child: CreateTaskWidget()));
  }
}
