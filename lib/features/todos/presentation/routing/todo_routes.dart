import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:taskee/app/routing/app_route.dart';
import '../../domain/entities/todo.dart';
import '../pages/add/add_todo_screen.dart';
import '../pages/home/home_screen.dart';
import '../pages/update/update_todo_screen.dart';

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
          return const AddTodoScreen();
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

