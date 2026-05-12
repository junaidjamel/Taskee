import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/helper/title_field_validator.dart';
import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/presentation/bloc/note_bloc.dart';
import 'package:taskee/features/note/presentation/bloc/note_event.dart';
import 'package:taskee/features/widget/app_button.dart';

class CreateNoteWidget extends StatefulWidget {
  const CreateNoteWidget({super.key});

  @override
  State<CreateNoteWidget> createState() => _CreateNoteWidgetState();
}

class _CreateNoteWidgetState extends State<CreateNoteWidget> {
  final _noteController = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _form,
          child: ListView(
            shrinkWrap: true,
            children: [
              30.kH,
              const Text('Write a Note'),
              10.kH,
              TextFormField(
                key: const Key('addTodo_title_textFormField'),
                controller: _noteController,
                maxLines: 8,

                validator: noteFieldValidator,
              ),

              60.kH,

              AppButton(
                text: 'Create Note',
                onTap: () {
                  if (_form.currentState!.validate()) {
                    _addNote();
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ).paddingSymmetric(horizontal: 20);
  }

  Future<void> _addNote() async {
    final note = Note(
      id: 0,
      note: _noteController.text,
      createdAt: DateTime.now(),
    );
    context.read<NoteBloc>().add(NoteItemAddedEvent(note));
  }
}
