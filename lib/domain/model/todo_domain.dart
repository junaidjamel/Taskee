class TodoDomain {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueAt;
  TodoDomain(
    this.id,
    this.title,
    this.description,
    this.isCompleted, {
    this.dueAt,
  });
}
