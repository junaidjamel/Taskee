import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabCubit extends Cubit<int> {
  TabCubit({int initialTab = 0}) : super(initialTab);

  static const _key = 'selected_tab';

  Future<void> changeTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
    emit(index);
  }
}
