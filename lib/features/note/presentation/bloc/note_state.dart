import 'package:equatable/equatable.dart';
import 'package:taskee/features/note/domain/model/note_list_model.dart';

abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

class NoteLoadingState extends NoteState {}

class NoteLoadedState extends NoteState {
  final NoteListModel noteModel;
  const NoteLoadedState(this.noteModel);

  @override
  List<Object?> get props => [];
}

class NoteErrorState extends NoteState {
  const NoteErrorState();
}
