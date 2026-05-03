import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:taskee/app/bloc/todo_bloc.dart';
import 'package:taskee/app/routing/go_router.dart';
import 'app/bloc/todo_event.dart';
import 'app/di/dependency_injection.dart';
import 'cache/database/app_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  AppDatabase database = AppDatabase();
  await database.initialize();
  configureDependencies(database);
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
    // Closes all Hive boxes
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => todoBloc..add(TodoStartedEvent())),
      ],
      child: MaterialApp.router(
        title: 'Hive Todo',
        theme: ThemeData(primarySwatch: Colors.purple),
        debugShowCheckedModeBanner: false,
        routerConfig: goRouter,
      ),
    );
  }
}
