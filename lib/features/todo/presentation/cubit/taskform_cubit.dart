import 'package:bloc/bloc.dart';

class TaskFormCubit extends Cubit<DateTime?> {
  TaskFormCubit(super.initialState);

  void updateDueAt(DateTime? dueAt) => emit(dueAt);
}
