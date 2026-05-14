import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/todo/presentation/cubit/taskform_cubit.dart';
import 'package:taskee/features/todo/presentation/pages/add/widgets/time_date_picker_widget.dart';
import 'package:taskee/features/widget/app_button.dart';

import '../../../../domain/entities/todo.dart';
import '../../../bloc/todo_bloc.dart';
import '../../../bloc/todo_event.dart';
import '../../../bloc/todo_state.dart';
import 'package:taskee/app/helper/title_field_validator.dart';

class CreateOrUpdateTaskWidget extends StatefulWidget {
  final Todo? todo;

  const CreateOrUpdateTaskWidget({super.key, this.todo});

  @override
  CreateOrUpdateTaskWidgetState createState() =>
      CreateOrUpdateTaskWidgetState();
}

class CreateOrUpdateTaskWidgetState extends State<CreateOrUpdateTaskWidget> {
  late final TextEditingController _titleController;
  final _todoFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.todo != null;

    return BlocProvider(
      create: (_) => TaskFormCubit(widget.todo?.dueAt),
      child: Builder(
        builder: (context) {
          return SingleChildScrollView(
            child: Column(
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
                          BlocBuilder<TaskFormCubit, DateTime?>(
                            builder: (context, dueAt) {
                              return DueAtPicker(
                                dueAt: dueAt,
                                onChanged: (value) => context
                                    .read<TaskFormCubit>()
                                    .updateDueAt(value),
                              );
                            },
                          ),
                          60.kH,

                          AppButton(
                            text: isUpdating ? 'Update Task' : 'Create Task',
                            onTap: () async {
                              final dueAt = context.read<TaskFormCubit>().state;
                              if (_todoFormKey.currentState!.validate() &&
                                  dueAt != null) {
                                if (isUpdating) {
                                  _updateTodo(context, dueAt);
                                } else {
                                  await _addTodo(context, dueAt);
                                }
                                if (context.mounted) context.pop();
                              } else if (dueAt == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select due date and time.',
                                    ),
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
            ).paddingSymmetric(horizontal: 20),
          );
        },
      ),
    );
  }

  Future<void> _addTodo(BuildContext context, DateTime dueAt) async {
    final todo = Todo(
      id: 0,
      title: _titleController.text,
      isCompleted: false,
      dueAt: dueAt,
    );
    context.read<TodoBloc>().add(TodoItemAddedEvent(todo));
  }

  void _updateTodo(BuildContext context, DateTime dueAt) {
    final todo = Todo(
      id: widget.todo!.id,
      title: _titleController.text,
      isCompleted: widget.todo!.isCompleted,
      dueAt: dueAt,
    );
    context.read<TodoBloc>().add(TodoItemUpdatedEvent(todo));
  }
}
