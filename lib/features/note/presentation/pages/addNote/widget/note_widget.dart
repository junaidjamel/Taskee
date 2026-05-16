import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/theme/app_assets.dart';
import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/presentation/bloc/note_bloc.dart';
import 'package:taskee/features/note/presentation/bloc/note_state.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:taskee/features/note/presentation/pages/addNote/widget/note_card.dart';
import 'package:taskee/features/todo/presentation/pages/add/create_taskOrNote_screen.dart';

class NoteWidget extends StatefulWidget {
  const NoteWidget({super.key});

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state is NoteLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NoteLoadedState) {
          final notes = state.noteModel.noteList;

          if (notes.isEmpty) {
            return Center(
              child: Image.asset(
                AppAssets.noDataImg,
                height: context.screenHeight * .25,
              ),
            );
          }

          final size = MediaQuery.of(context).size;
          final cardW = size.width * 0.5;
          final cardH = size.height * 0.4;

          return CardSwiper(
            controller: _controller,
            cardsCount: notes.length,
            isLoop: true,
            numberOfCardsDisplayed: notes.length.clamp(1, 3),
            maxAngle: 50,
            threshold: 50,
            padding: const EdgeInsets.only(
              left: 40,
              bottom: 130,
              right: 40,
              top: 30,
            ),

            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
                  final note = notes[index];
                  final isFront = index % 2 == 0;
                  return GestureDetector(
                    onTap: () => context.gotTo(
                      CreateTaskOrNoteScreen(
                        note: note,
                        isUpdateTaskscreen: true,
                      ),
                    ),
                    child: NoteCard(
                      note: note,
                      isLight: isFront,
                      cardW: cardW,
                      cardH: cardH,
                      onDelete: () {},
                    ),
                  );
                },
            onSwipe: (previousIndex, currentIndex, direction) => true,
          );
        }

        return const Text('Something went wrong!');
      },
    );
  }
}
