import '../../domain/entities/todo.dart';
import '../models/todo_hive_model.dart';

extension TodoHiveModelToDomain on TodoHiveModel {
  Todo toDomain() {
    // Backward compatibility: older records may have no dueAt.
    return Todo(
      id: id,
      title: title,
      isCompleted: isCompleted,
      dueAt: dueAt ?? DateTime.now(),
    );
  }
}

extension TodoDomainToHiveModel on Todo {
  TodoHiveModel toHiveModel() {
    return TodoHiveModel(
      id: id,
      title: title,
      isCompleted: isCompleted,
      dueAt: dueAt,
    );
  }
}
