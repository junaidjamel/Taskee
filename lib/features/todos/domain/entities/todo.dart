class Todo {
  final int id;
  final String title;
  final bool isCompleted;
  final DateTime dueAt;

  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.dueAt,
  });
}
