import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/theme/app_assets.dart';
import 'package:taskee/features/todo/domain/entities/todo.dart';
import 'package:taskee/features/todo/presentation/bloc/todo_bloc.dart';
import 'package:taskee/features/todo/presentation/bloc/todo_event.dart';
import 'package:taskee/features/todo/presentation/bloc/todo_state.dart';
import 'package:taskee/features/todo/presentation/pages/add/create_taskOrNote_screen.dart';
import 'package:taskee/features/todo/presentation/pages/home/widget/todo_list_item.dart';

class TaskWidget extends StatelessWidget {
  const TaskWidget({super.key});

  void onClickUndo(Todo todo, BuildContext context) {
    context.read<TodoBloc>().add(TodoItemUndoDeletedEvent(todo));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TodoLoadedState) {
          if (state.todoModel.todoList.isEmpty) {
            return Center(
              child: Image.asset(
                AppAssets.noDataImg,
                height: context.screenHeight * .25,
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: state.todoModel.todoList.length,
            itemBuilder: (context, index) {
              final todo = state.todoModel.todoList[index];
              return TodoListItem(
                todo: todo,
                onClickItem: () {
                  context.gotTo(CreateTaskOrNoteScreen(todo: todo));
                },
                onClickDelete: () {
                  context.read<TodoBloc>().add(TodoItemDeletedEvent(todo.id));
                  // AppUtils.showSnackBar(
                  //   context: context,
                  //   message: '${todo.title} is deleted',
                  //   label: 'Undo',
                  //   onPress: () => onClickUndo(todo, context),
                  // );
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
    );
  }
}
