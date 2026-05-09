import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/features/widget/app_gradient.dart';

import '../../../domain/entities/todo.dart';
import '../../bloc/todo_bloc.dart';
import '../../bloc/todo_event.dart';
import '../../bloc/todo_state.dart';
import '../../widgets/todo_list_item.dart';
import 'package:taskee/app/helper/app_utils.dart';
import 'package:taskee/app/routing/app_route.dart';

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
        onPressed: () => context.push("/${Routes.addScreen}"),
        child: const Icon(Icons.add),
      ),
      body: AppGradient(
        child: BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            if (state is TodoLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TodoLoadedState) {
              if (state.todoModel.todoList.isEmpty) {
                return const Center(child: Text('Empty'));
              }
              return ListView.builder(
                itemCount: state.todoModel.todoList.length,
                itemBuilder: (context, index) {
                  final todo = state.todoModel.todoList[index];
                  return TodoListItem(
                    todo: todo,
                    onClickItem: () {
                      context.push(
                        "/${Routes.updateScreen}",
                        extra: {"todo": todo},
                      );
                    },
                    onClickDelete: () {
                      context.read<TodoBloc>().add(
                        TodoItemDeletedEvent(todo.id),
                      );
                      AppUtils.showSnackBar(
                        context: context,
                        message: '${todo.title} is deleted',
                        label: 'Undo',
                        onPress: () => onClickUndo(todo),
                      );
                    },
                    onToggleComplete: () {
                      context.read<TodoBloc>().add(
                        TodoItemToggleCompletedEvent(todo),
                      );
                    },
                  );
                },
              );
            }
            return const Text('Something went wrong!');
          },
        ),
      ),
    );
  }

  void onClickUndo(Todo todo) {
    context.read<TodoBloc>().add(TodoItemUndoDeletedEvent(todo));
  }
}
