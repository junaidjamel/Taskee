import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/features/notes/presentation/bloc/note_bloc.dart';
import 'package:taskee/features/notes/presentation/bloc/note_event.dart';
import 'package:taskee/features/notes/presentation/bloc/note_state.dart';
import 'package:taskee/features/todos/presentation/pages/home/widget/note_card.dart';

class NoteWidget extends StatelessWidget {
  const NoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state is NoteLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        // data
        if (state is NoteLoadedState) {
          if (state.noteModel.noteList.isEmpty) {
            return Center(
              child: Image.network(
                'https://img.magnific.com/free-vector/hand-drawn-no-data-illustration_23-2150570252.jpg?semt=ais_hybrid&w=740&q=80',
                height: context.screenHeight * .25,
              ),
            );
          }
          return SizedBox(
            height: context.screenHeight * .6,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.noteModel.noteList.length,

              itemBuilder: (context, index) {
                final note = state.noteModel.noteList[index];
                return NoteCard(
                  note: note,
                  onClickItem: () {
                    // context.push(
                    //   "/${Routes.updateScreen}",
                    //   extra: {"todo": todo},
                    // );
                  },
                  onClickDelete: () {
                    context.read<NoteBloc>().add(NoteItemDeletedEvent(note.id));
                  },
                ).paddingSymmetric(horizontal: 20);
              },
            ),
          );
        }
        return const Text('Something went wrong!');
      },
    );
  }
}
