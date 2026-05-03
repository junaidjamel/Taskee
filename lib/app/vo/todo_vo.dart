import 'package:equatable/equatable.dart';

class TodoVO extends Equatable{
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  TodoVO(
      {required this.id,
      required this.title,
      required this.description,
      required this.isCompleted});

  @override
  List<Object?> get props => [id,title,description,isCompleted];
}
