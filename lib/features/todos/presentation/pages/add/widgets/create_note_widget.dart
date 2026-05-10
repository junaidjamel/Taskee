import 'package:flutter/material.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/helper/title_field_validator.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_button.dart';

class NoteWidget extends StatefulWidget {
  const NoteWidget({super.key});

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  final _titleController = TextEditingController();
  final _todoFormKey = GlobalKey<FormState>();

  DateTime? _dueAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _todoFormKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              30.kH,
              const Text('Write a Note'),
              10.kH,
              TextFormField(
                key: const Key('addTodo_title_textFormField'),
                controller: _titleController,
                maxLines: 6,

                validator: titleFieldValidator,
                decoration: InputDecoration(
                  hintText: 'Task Name',
                  hintStyle: AppTypography.bodyMd,
                ),
              ),

              60.kH,

              AppButton(
                text: 'Create Note',
                onTap: () {
                  if (_todoFormKey.currentState!.validate() && _dueAt != null) {
                    // _addTodo();
                    // context.pop();
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
        ),
      ],
    ).paddingSymmetric(horizontal: 20);
  }
}
