class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.technologies = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> technologies;
  final DateTime createdAt;

  String get matchingText => [
        name,
        description,
        ...technologies,
      ].join(' ').toLowerCase();
}
