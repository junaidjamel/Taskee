import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
class TodoEntity {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isCompleted;

  TodoEntity(
      {required this.id,
      required this.title,
      required this.description,
      required this.isCompleted});
}
