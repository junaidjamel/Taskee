import 'package:hive/hive.dart';

part 'todo_hive_model.g.dart';

@HiveType(typeId: 1)
class TodoHiveModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final DateTime? dueAt;

  const TodoHiveModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.dueAt,
  });
}

