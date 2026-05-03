import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/vo/todo_vo.dart';
import '../../bloc/todo_bloc.dart';
import '../../bloc/todo_event.dart';
import '../../bloc/todo_state.dart';
import '../../helper/app_utils.dart';
import '../../routing/app_route.dart';
import 'component/todo_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hive Todo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push("/${Routes.addScreen}"),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is TodoLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TodoLoadedState) {
            if (state.todoModel.todoList.isEmpty) {
              return const Center(child: Text('Empty'));
            } else {
              return ListView.builder(
                itemCount: state.todoModel.todoList.length,
                itemBuilder: (context, index) {
                  var todoVO = state.todoModel.todoList[index];
                  return TodoListItem(
                    todoVO: todoVO,
                    onClickItem: () => {
                      context.push(
                        "/${Routes.updateScreen}",
                        extra: {"todo": todoVO},
                      ),
                    },
                    onClickDelete: () => {
                      context.read<TodoBloc>().add(
                        TodoItemDeletedEvent(todoVO.id),
                      ),
                      AppUtils.showSnackBar(
                        context: context,
                        message: '${todoVO.title} is deleted',
                        label: 'Undo',
                        onPress: () => {onClickUndo(todoVO)},
                      ),
                    },
                    onToggleComplete: () => {
                      context.read<TodoBloc>().add(
                        TodoItemToggleCompletedEvent(todoVO),
                      ),
                    },
                  );
                },
              );
            }
          }
          return const Text('Something went wrong!');
        },
      ),
    );
  }

  void onClickUndo(TodoVO todoVO) {
    context.read<TodoBloc>().add(TodoItemUndoDeletedEvent(todoVO));
  }
}
