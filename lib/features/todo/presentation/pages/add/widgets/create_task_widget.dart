import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/todo/presentation/pages/add/widgets/time_date_picker_widget.dart';
import 'package:taskee/features/widget/app_button.dart';

import '../../../../domain/entities/todo.dart';
import '../../../bloc/todo_bloc.dart';
import '../../../bloc/todo_event.dart';
import '../../../bloc/todo_state.dart';
import 'package:taskee/app/helper/title_field_validator.dart';

class CreateTaskWidget extends StatefulWidget {
  final Todo? todo;

  const CreateTaskWidget({super.key, this.todo});

  @override
  CreateTaskWidgetState createState() => CreateTaskWidgetState();
}

class CreateTaskWidgetState extends State<CreateTaskWidget> {
  late final TextEditingController _titleController;
  final _todoFormKey = GlobalKey<FormState>();
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _dueAt = widget.todo?.dueAt;
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.todo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            return Form(
              key: _todoFormKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  30.kH,
                  const Text('Title'),
                  10.kH,
                  TextFormField(
                    key: const Key('addTodo_title_textFormField'),
                    controller: _titleController,
                    maxLines: 1,

                    validator: todoFieldValidator,
                    decoration: InputDecoration(
                      hintText: 'Write Task title ...',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.kgrey,
                      ),
                    ),
                  ),
                  30.kH,
                  const Text('Time & Date (required)'),
                  10.kH,
                  DueAtPicker(
                    dueAt: _dueAt,
                    onChanged: (value) => setState(() => _dueAt = value),
                  ),
                  60.kH,

                  AppButton(
                    text: isUpdating ? 'Update Task' : 'Create Task',
                    onTap: () {
                      if (_todoFormKey.currentState!.validate() &&
                          _dueAt != null) {
                        isUpdating ? _updateTodo() : _addTodo();
                        context.pop();
                      } else if (_dueAt == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select due date and time.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).paddingSymmetric(horizontal: 20);
  }

  Future<void> _addTodo() async {
    final dueAt = _dueAt ?? DateTime.now();
    final todo = Todo(
      id: 0,
      title: _titleController.text,
      isCompleted: false,
      dueAt: dueAt,
    );
    context.read<TodoBloc>().add(TodoItemAddedEvent(todo));
  }

  void _updateTodo() {
    final dueAt = _dueAt ?? DateTime.now();
    final todo = Todo(
      id: widget.todo!.id,
      title: _titleController.text,
      isCompleted: widget.todo!.isCompleted,
      dueAt: dueAt,
    );
    context.read<TodoBloc>().add(TodoItemUpdatedEvent(todo));
  }
}
