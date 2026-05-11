import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/app/theme/app_theme.dart';
import 'package:taskee/features/notes/data/datasource/hive_note_local_datasource.dart';
import 'package:taskee/features/notes/presentation/bloc/note_bloc.dart';
import 'package:taskee/features/notes/presentation/bloc/note_event.dart';
import 'package:taskee/features/todos/presentation/bloc/todo_bloc.dart';
import 'package:taskee/app/routing/go_router.dart';
import 'package:taskee/features/todos/presentation/bloc/todo_event.dart';
import 'package:taskee/di/dependency_injection.dart';
import 'package:taskee/features/todos/data/datasource/hive_todo_local_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final hiveTodoLocalDataSource = HiveTodoLocalDataSource();
  await hiveTodoLocalDataSource.initialize();

  final hiveNoteLocalDatasource = HiveNoteLocalDatasource();
  await hiveNoteLocalDatasource.initialize();

  configureDependencies(
    hiveTodoLocalDataSource: hiveTodoLocalDataSource,
    hiveNoteLocalDatasource: hiveNoteLocalDatasource,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final TodoBloc todoBloc = getIt<TodoBloc>();
  final NoteBloc noteBloc = getIt<NoteBloc>();

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
        BlocProvider(create: (_) => noteBloc..add(NoteStartedEvent())),
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
