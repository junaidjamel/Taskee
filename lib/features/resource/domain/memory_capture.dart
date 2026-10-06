enum MemoryCaptureKind { url, text, image, audio, video, file, email, calendar, message }

/// The normalized doorway into NanyNany.
///
/// Platform adapters should translate whatever they receive into this shape.
/// Understanding, storage, retrieval and reminder logic should consume this
/// contract rather than knowing whether the item came from iOS, Android,
/// WhatsApp, a browser, email, or another future integration.
class MemoryCapture {
  final String id;
  final MemoryCaptureKind kind;
  final String source;
  final DateTime capturedAt;
  final String? title;
  final String? text;
  final String? canonicalUrl;
  final String? localPath;
  final String? mimeType;
  final String? userContext;
  final DateTime? eventAt;
  final String? timezoneEvidence;
  final double? eventConfidence;
  final Map<String, String> provenance;

  const MemoryCapture({
    required this.id,
    required this.kind,
    required this.source,
    required this.capturedAt,
    this.title,
    this.text,
    this.canonicalUrl,
    this.localPath,
    this.mimeType,
    this.userContext,
    this.eventAt,
    this.timezoneEvidence,
    this.eventConfidence,
    this.provenance = const {},
  });

  factory MemoryCapture.now({
    required MemoryCaptureKind kind,
    required String source,
    String? title,
    String? text,
    String? canonicalUrl,
    String? localPath,
    String? mimeType,
    String? userContext,
    Map<String, String> provenance = const {},
  }) {
    final now = DateTime.now();
    return MemoryCapture(
      id: now.microsecondsSinceEpoch.toString(),
      kind: kind,
      source: source,
      capturedAt: now,
      title: title,
      text: text,
      canonicalUrl: canonicalUrl,
      localPath: localPath,
      mimeType: mimeType,
      userContext: userContext,
      provenance: provenance,
    );
  }

  String get searchableText => [
        title,
        text,
        canonicalUrl,
        userContext,
        source,
      ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n');

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'source': source,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        if (title != null) 'title': title,
        if (text != null) 'text': text,
        if (canonicalUrl != null) 'canonicalUrl': canonicalUrl,
        if (localPath != null) 'localPath': localPath,
        if (mimeType != null) 'mimeType': mimeType,
        if (userContext != null) 'userContext': userContext,
        if (eventAt != null) 'eventAt': eventAt!.toUtc().toIso8601String(),
        if (timezoneEvidence != null) 'timezoneEvidence': timezoneEvidence,
        if (eventConfidence != null) 'eventConfidence': eventConfidence,
        'provenance': provenance,
      };
}