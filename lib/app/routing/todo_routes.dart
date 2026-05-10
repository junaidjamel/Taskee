import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:taskee/app/routing/app_route.dart';
import '../../features/todos/domain/entities/todo.dart';
import '../../features/todos/presentation/pages/add/create_taskOrNote_screen.dart';
import '../../features/todos/presentation/pages/home/home_screen.dart';
import '../../features/todos/presentation/pages/update/update_todo_screen.dart';

final List<RouteBase> todoRoutes = <RouteBase>[
  GoRoute(
    path: Routes.homeScreen,
    builder: (BuildContext context, GoRouterState state) {
      return const HomeScreen();
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.addScreen,
        builder: (BuildContext context, GoRouterState state) {
          return const CreateTaskOrNoteScreen();
        },
      ),
      GoRoute(
        path: Routes.updateScreen,
        builder: (BuildContext context, GoRouterState state) {
          final args = state.extra as Map<String, dynamic>;
          return UpdateTodoScreen(todo: args['todo'] as Todo);
        },
      ),
    ],
  ),
];
