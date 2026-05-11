import 'package:bloc/bloc.dart';
import 'package:taskee/features/notes/domain/entities/note.dart';
import 'package:taskee/features/notes/domain/model/note_list_model.dart';
import 'package:taskee/features/notes/domain/usecase/add_note.dart';
import 'package:taskee/features/notes/domain/usecase/delete_note.dart';
import 'package:taskee/features/notes/domain/usecase/get_all_notes.dart';
import 'package:taskee/features/notes/domain/usecase/update_note.dart';
import 'package:taskee/features/notes/presentation/bloc/note_event.dart';
import 'package:taskee/features/notes/presentation/bloc/note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetAllNotes getAllNotes;
  final AddNote addNote;
  final UpdateNote updateNote;
  final DeleteNote deleteNote;

  NoteBloc({
    required this.getAllNotes,
    required this.addNote,
    required this.updateNote,
    required this.deleteNote,
  }) : super(NoteLoadingState()) {
    on<NoteStartedEvent>(_onStarted);
    on<NoteItemAddedEvent>(_onItemAdded);
    on<NoteItemUpdatedEvent>(_onItemUpdated);
    on<NoteItemDeletedEvent>(_onItemDeleted);
  }

  void _onStarted(NoteStartedEvent event, Emitter<NoteState> emit) {
    emit(NoteLoadingState());
    try {
      final noteList = getAllNotes();
      emit(NoteLoadedState(NoteListModel(noteList: noteList)));
    } catch (_) {
      emit(const NoteErrorState());
    }
  }

  void _onItemAdded(NoteItemAddedEvent event, Emitter<NoteState> emit) {
    emit(NoteLoadingState());
    try {
      addNote(event.note);
      add(NoteStartedEvent());
    } catch (_) {
      emit(const NoteErrorState());
    }
  }

  void _onItemUpdated(NoteItemUpdatedEvent event, Emitter<NoteState> emit) {
    emit(NoteLoadingState());
    try {
      updateNote(event.note);
      add(NoteStartedEvent());
    } catch (_) {
      emit(const NoteErrorState());
    }
  }

  void _onItemDeleted(NoteItemDeletedEvent event, Emitter<NoteState> emit) {
    emit(NoteLoadingState());
    try {
      deleteNote(event.id);
      add(NoteStartedEvent());
    } catch (_) {
      emit(const NoteErrorState());
    }
  }
}
