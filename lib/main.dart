import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:taskee/app/theme/app_theme.dart';
import 'package:taskee/features/todos/presentation/bloc/todo_bloc.dart';
import 'package:taskee/app/routing/go_router.dart';
import 'package:taskee/features/todos/presentation/bloc/todo_event.dart';
import 'package:taskee/di/dependency_injection.dart';
import 'package:taskee/features/todos/data/datasource/hive_todo_local_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  final hiveTodoLocalDataSource = HiveTodoLocalDataSource();
  await hiveTodoLocalDataSource.initialize();
  configureDependencies(hiveTodoLocalDataSource: hiveTodoLocalDataSource);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final TodoBloc todoBloc = getIt<TodoBloc>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => todoBloc..add(TodoStartedEvent())),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),

        child: MaterialApp.router(
          title: 'Taskee App',
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          routerConfig: goRouter,
        ),
      ),
    );
  }
}
