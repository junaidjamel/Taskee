enum CommitmentKind { appointment, meeting, deadline, schedule, followUp }

enum CommitmentStatus { needsConfirmation, upcoming, preparing, ready, onMyWay, done, dismissed }

class Commitment {
  final String id;
  final String title;
  final DateTime dueAt;
  final CommitmentKind kind;
  final CommitmentStatus status;
  final String? source;
  final String? detail;

  const Commitment({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.kind,
    required this.status,
    this.source,
    this.detail,
  });

  Commitment copyWith({CommitmentStatus? status}) => Commitment(
    id: id, title: title, dueAt: dueAt, kind: kind,
    status: status ?? this.status, source: source, detail: detail,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'dueAt': dueAt.toIso8601String(),
    'kind': kind.name, 'status': status.name, 'source': source, 'detail': detail,
  };

  factory Commitment.fromMap(Map<String, dynamic> map) => Commitment(
    id: map['id'] as String,
    title: map['title'] as String,
    dueAt: DateTime.parse(map['dueAt'] as String),
    kind: CommitmentKind.values.firstWhere((e) => e.name == map['kind'], orElse: () => CommitmentKind.deadline),
    status: CommitmentStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => CommitmentStatus.upcoming),
    source: map['source'] as String?,
    detail: map['detail'] as String?,
  );
}
