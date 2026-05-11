import 'package:equatable/equatable.dart';
import 'package:taskee/features/notes/domain/entities/note.dart';

class NoteListModel extends Equatable {
  const NoteListModel({required this.noteList});

  final List<Note> noteList;

  @override
  List<Object> get props => [noteList];
}
