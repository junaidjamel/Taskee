enum ResourceType {
  website,
  video,
  github,
  screenshot,
  article,
  tool,
  tutorial,
  code,
  session,
  other,
}

enum ResourceStatus {
  saved,
  seen,
  used,
  useful,
  archived,
}

class Resource {
  const Resource({
    required this.id,
    required this.title,
    required this.summary,
    required this.whyUseful,
    required this.useWhen,
    required this.savedAt,
    this.url,
    this.creator,
    this.platform,
    this.thumbnail,
    this.assetPath,
    this.transcript,
    this.session,
    this.type = ResourceType.other,
    this.status = ResourceStatus.saved,
    this.topics = const [],
    this.technologies = const [],
    this.lastUsedAt,
  });

  final String id;
  final String title;
  final String? url;
  final String? creator;
  final String? platform;
  final String summary;
  final String whyUseful;
  final String useWhen;
  final String? thumbnail;
  final String? assetPath;
  final String? transcript;
  final Map<String, dynamic>? session;
  final ResourceType type;
  final ResourceStatus status;
  final List<String> topics;
  final List<String> technologies;
  final DateTime savedAt;
  final DateTime? lastUsedAt;

  String get searchableText => [
        title,
        creator,
        platform,
        summary,
        whyUseful,
        useWhen,
        transcript,
        ...topics,
        ...technologies,
        if (session != null) _sessionSearchText(session!),
      ].whereType<String>().join(' ').toLowerCase();

  static String _sessionSearchText(Map<String, dynamic> session) {
    final groups = session['groups'];
    if (groups is! List) return '';
    return groups.expand<String>((raw) {
      if (raw is! Map) return const <String>[];
      final group = Map<String, dynamic>.from(raw);
      final tabs = group['tabs'];
      return <String>[
        group['title']?.toString() ?? '',
        group['whatYouWereDoing']?.toString() ?? '',
        if (tabs is List)
          ...tabs.expand<String>((tabRaw) {
            if (tabRaw is! Map) return const <String>[];
            final tab = Map<String, dynamic>.from(tabRaw);
            return [tab['title']?.toString() ?? '', tab['url']?.toString() ?? ''];
          }),
      ];
    }).join(' ');
  }

  Resource copyWith({
    String? title,
    String? url,
    String? creator,
    String? platform,
    String? summary,
    String? whyUseful,
    String? useWhen,
    String? thumbnail,
    String? assetPath,
    String? transcript,
    Map<String, dynamic>? session,
    ResourceType? type,
    ResourceStatus? status,
    List<String>? topics,
    List<String>? technologies,
    DateTime? lastUsedAt,
  }) {
    return Resource(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      creator: creator ?? this.creator,
      platform: platform ?? this.platform,
      summary: summary ?? this.summary,
      whyUseful: whyUseful ?? this.whyUseful,
      useWhen: useWhen ?? this.useWhen,
      thumbnail: thumbnail ?? this.thumbnail,
      assetPath: assetPath ?? this.assetPath,
      transcript: transcript ?? this.transcript,
      session: session ?? this.session,
      type: type ?? this.type,
      status: status ?? this.status,
      topics: topics ?? this.topics,
      technologies: technologies ?? this.technologies,
      savedAt: savedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'creator': creator,
        'platform': platform,
        'summary': summary,
        'whyUseful': whyUseful,
        'useWhen': useWhen,
        'thumbnail': thumbnail,
        'assetPath': assetPath,
        'transcript': transcript,
        'session': session,
        'type': type.name,
        'status': status.name,
        'topics': topics,
        'technologies': technologies,
        'savedAt': savedAt.toIso8601String(),
        'lastUsedAt': lastUsedAt?.toIso8601String(),
      };

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String?,
      creator: map['creator'] as String?,
      platform: map['platform'] as String?,
      summary: map['summary'] as String? ?? '',
      whyUseful: map['whyUseful'] as String? ?? '',
      useWhen: map['useWhen'] as String? ?? '',
      thumbnail: map['thumbnail'] as String?,
      assetPath: map['assetPath'] as String?,
      transcript: map['transcript'] as String?,
      session: map['session'] is Map ? Map<String, dynamic>.from(map['session'] as Map) : null,
      type: ResourceType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ResourceType.other,
      ),
      status: ResourceStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => ResourceStatus.saved,
      ),
      topics: List<String>.from(map['topics'] as List? ?? const []),
      technologies: List<String>.from(map['technologies'] as List? ?? const []),
      savedAt: DateTime.tryParse(map['savedAt'] as String? ?? '') ?? DateTime.now(),
      lastUsedAt: map['lastUsedAt'] == null
          ? null
          : DateTime.tryParse(map['lastUsedAt'] as String),
    );
  }
}
