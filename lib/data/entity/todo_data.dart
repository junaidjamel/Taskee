class TodoData {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueAt;
  TodoData(
    this.id,
    this.title,
    this.description,
    this.isCompleted, {
    this.dueAt,
  });
}
