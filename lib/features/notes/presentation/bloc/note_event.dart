import 'package:equatable/equatable.dart';
import 'package:taskee/features/notes/domain/entities/note.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class NoteStartedEvent extends NoteEvent {}

class NoteItemAddedEvent extends NoteEvent {
  final Note note;

  const NoteItemAddedEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteItemUpdatedEvent extends NoteEvent {
  final Note note;

  const NoteItemUpdatedEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteItemDeletedEvent extends NoteEvent {
  final int id;

  const NoteItemDeletedEvent(this.id);

  @override
  List<Object?> get props => [id];
}
