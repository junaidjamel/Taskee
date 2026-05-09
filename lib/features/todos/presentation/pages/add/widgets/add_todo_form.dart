import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/todo.dart';
import '../../../bloc/todo_bloc.dart';
import '../../../bloc/todo_event.dart';
import '../../../bloc/todo_state.dart';
import 'package:taskee/app/helper/description_field_validator.dart.dart';
import 'package:taskee/app/helper/title_field_validator.dart';

class AddTodoForm extends StatefulWidget {
  const AddTodoForm({super.key});

  @override
  AddTodoFormState createState() => AddTodoFormState();
}

class AddTodoFormState extends State<AddTodoForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _todoFormKey = GlobalKey<FormState>();

  DateTime? _dueAt;

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
              const Text('Due date & time (required)'),
              const SizedBox(height: 8.0),
              _DueAtPicker(
                dueAt: _dueAt,
                onChanged: (value) => setState(() => _dueAt = value),
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_todoFormKey.currentState!.validate() &&
                          _dueAt != null) {
                        _addTodo();
                        context.pop();
                      } else if (_dueAt == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select due date and time.'),
                          ),
                        );
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
    final dueAt = _dueAt ?? DateTime.now();
    final todo = Todo(
      id: 0,
      title: _titleController.text,
      description: _descriptionController.text,
      isCompleted: false,
      dueAt: dueAt,
    );
    context.read<TodoBloc>().add(TodoItemAddedEvent(todo));
  }
}

class _DueAtPicker extends StatelessWidget {
  const _DueAtPicker({
    required this.dueAt,
    required this.onChanged,
  });

  final DateTime? dueAt;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel =
        dueAt == null ? 'Select date' : localizations.formatFullDate(dueAt!);
    final timeLabel = dueAt == null
        ? 'Select time'
        : localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(dueAt!),
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          key: const Key('addTodo_dueDate_button'),
          onPressed: () async {
            final now = DateTime.now();
            final initial = dueAt ?? now;
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(initial.year, initial.month, initial.day),
              firstDate: DateTime(now.year - 10),
              lastDate: DateTime(now.year + 20),
            );
            if (picked == null) return;
            final currentTime = dueAt == null
                ? const TimeOfDay(hour: 9, minute: 0)
                : TimeOfDay.fromDateTime(dueAt!);
            onChanged(DateTime(
              picked.year,
              picked.month,
              picked.day,
              currentTime.hour,
              currentTime.minute,
            ));
          },
          child: Text('Date: $dateLabel'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('addTodo_dueTime_button'),
          onPressed: () async {
            final initial = dueAt == null
                ? const TimeOfDay(hour: 9, minute: 0)
                : TimeOfDay.fromDateTime(dueAt!);
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked == null) return;
            final base = dueAt ?? DateTime.now();
            onChanged(DateTime(
              base.year,
              base.month,
              base.day,
              picked.hour,
              picked.minute,
            ));
          },
          child: Text('Time: $timeLabel'),
        ),
      ],
    );
  }
}

