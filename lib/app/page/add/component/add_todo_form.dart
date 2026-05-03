import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/vo/todo_vo.dart';
import '../../../bloc/todo_bloc.dart';
import '../../../bloc/todo_event.dart';
import '../../../bloc/todo_state.dart';
import '../../../helper/description_field_validator.dart.dart';
import '../../../helper/title_field_validator.dart';

class AddTodoForm extends StatefulWidget {
  const AddTodoForm({super.key});

  @override
  AddTodoFormState createState() => AddTodoFormState();
}

class AddTodoFormState extends State<AddTodoForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _todoFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        return Form(
          key: _todoFormKey,
          child: ListView(
            children: [
              const SizedBox(height: 24.0),
              const Text('Title'),
              TextFormField(
                key: const Key('addTodo_title_textFormField'),
                controller: _titleController,
                maxLines: 1,
                maxLength: 50,
                validator: titleFieldValidator,
              ),
              const SizedBox(height: 24.0),
              const Text('Description'),
              TextFormField(
                key: const Key('addTodo_description_textFormField'),
                controller: _descriptionController,
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                validator: descriptionFieldValidator,
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_todoFormKey.currentState!.validate()) {
                        _addTodo();
                        context.pop();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTodo() async {
    TodoVO todoVO = TodoVO(
      id: 0,
      title: _titleController.text,
      description: _descriptionController.text,
      isCompleted: false,
    );
    context.read<TodoBloc>().add(TodoItemAddedEvent(todoVO));
  }
}
