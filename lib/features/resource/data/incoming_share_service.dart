import 'package:cross_file/cross_file.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:resource_memory/features/resource/data/cloud_sync_service.dart';
import 'package:resource_memory/features/resource/data/resource_enrichment_service.dart';
import 'package:resource_memory/features/resource/data/resource_link_service.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/domain/memory_capture.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';

class IncomingShareService {
  static Future<int> saveSharedItems(List<SharedMediaFile> items) async {
    var saved = 0;
    for (final item in items) {
      final capture = _captureFromSharedMedia(item);
      if (await saveCapture(capture)) saved++;
    }
    return saved;
  }

  /// Shared ingestion doorway for current and future platform adapters.
  static Future<bool> saveCapture(MemoryCapture capture) async {
    switch (capture.kind) {
      case MemoryCaptureKind.url:
      case MemoryCaptureKind.text:
      case MemoryCaptureKind.email:
      case MemoryCaptureKind.calendar:
      case MemoryCaptureKind.message:
        return _saveTextOrUrl(capture);
      case MemoryCaptureKind.image:
        return _saveImage(capture);
      case MemoryCaptureKind.audio:
        return _saveAudio(capture);
      case MemoryCaptureKind.video:
      case MemoryCaptureKind.file:
        return _saveFile(capture);
    }
  }

  static MemoryCapture _captureFromSharedMedia(SharedMediaFile item) {
    final path = item.path;
    final kind = switch (item.type) {
      SharedMediaType.url => MemoryCaptureKind.url,
      SharedMediaType.text => MemoryCaptureKind.text,
      SharedMediaType.image => MemoryCaptureKind.image,
      SharedMediaType.video => MemoryCaptureKind.video,
      SharedMediaType.file => _isAudioPath(path)
          ? MemoryCaptureKind.audio
          : MemoryCaptureKind.file,
    };

    return MemoryCapture.now(
      kind: kind,
      source: 'system_share_sheet',
      text: item.message,
      canonicalUrl: kind == MemoryCaptureKind.url ? path : null,
      localPath: {
        MemoryCaptureKind.image,
        MemoryCaptureKind.audio,
        MemoryCaptureKind.video,
        MemoryCaptureKind.file,
      }.contains(kind)
          ? path
          : null,
      provenance: {
        'adapter': 'receive_sharing_intent',
        'sharedType': item.type.name,
        if (kind == MemoryCaptureKind.text) 'rawText': path,
      },
    );
  }

  static Future<bool> _saveTextOrUrl(MemoryCapture capture) async {
    final raw = capture.provenance['rawText'];
    final text = [capture.canonicalUrl, raw, capture.text]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (text.isEmpty) return false;

    final url = capture.canonicalUrl ?? _firstUrl(text);
    if (url != null) {
      if (_alreadySaved(url)) return false;
      final draft = await ResourceEnrichmentService.enrich(url);
      await ResourceStore.save(
        Resource(
          id: capture.id,
          title: draft.title,
          url: url,
          creator: draft.creator,
          platform: draft.platform,
          summary: draft.summary,
          whyUseful: draft.whyUseful,
          useWhen: draft.useWhen,
          thumbnail: draft.thumbnail,
          type: draft.type,
          topics: draft.topics,
          technologies: draft.technologies,
          savedAt: capture.capturedAt,
        ),
      );
      return true;
    }

    await ResourceStore.save(
      Resource(
        id: capture.id,
        title: capture.title ?? _titleFromText(text),
        platform: _platformLabel(capture),
        summary: text,
        whyUseful: 'You saved this because it contained an idea, explanation, event, message, or reference worth keeping.',
        useWhen: 'Resurface when a project, commitment, person, or learning goal overlaps with this memory.',
        type: ResourceType.article,
        topics: [_topicLabel(capture)],
        savedAt: capture.capturedAt,
      ),
    );
    return true;
  }

  static Future<bool> _saveImage(MemoryCapture capture) async {
    final path = capture.localPath;
    if (path == null) return false;
    final name = _fileName(path, fallback: 'Shared screenshot');
    final bytes = await XFile(path).readAsBytes();
    if (bytes.isEmpty) return false;

    ImageResourceAnalysis? analysis;
    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        analysis = await CloudSyncService.analyzeImage(
          bytes: bytes,
          contentType: capture.mimeType ?? _imageContentType(name),
        );
      } catch (_) {}
    }

    final extractedUrl = analysis?.url == null
        ? null
        : ResourceLinkService.normalize(analysis!.url)?.toString();
    var resource = Resource(
      id: capture.id,
      title: analysis?.title ?? capture.title ?? name,
      url: extractedUrl,
      creator: analysis?.creator,
      platform: analysis?.platform ?? _platformLabel(capture),
      thumbnail: path,
      summary: analysis?.summary ?? capture.text ?? 'An image or screenshot saved into NanyNany.',
      whyUseful: analysis?.whyUseful ?? 'Useful as a visual reference you wanted Future You to keep.',
      useWhen: analysis?.useWhen ?? 'Resurface when the current project overlaps with the subject of this image.',
      type: analysis == null ? ResourceType.screenshot : _resourceTypeFromName(analysis.resourceType),
      topics: analysis?.topics ?? const ['screenshot', 'visual reference'],
      technologies: analysis?.technologies ?? const [],
      savedAt: capture.capturedAt,
    );
    await ResourceStore.save(resource);

    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: name,
          bytes: bytes,
          contentType: capture.mimeType ?? _imageContentType(name),
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> _saveAudio(MemoryCapture capture) async {
    final path = capture.localPath;
    if (path == null) return false;
    final name = _fileName(path, fallback: 'Shared voice memo');
    final bytes = await XFile(path).readAsBytes();
    if (bytes.isEmpty) return false;

    AudioResourceAnalysis? analysis;
    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        analysis = await CloudSyncService.analyzeAudio(
          bytes: bytes,
          contentType: capture.mimeType ?? _audioContentType(name),
        );
      } catch (_) {}
    }

    final extractedUrl = analysis?.url == null
        ? null
        : ResourceLinkService.normalize(analysis!.url)?.toString();
    var resource = Resource(
      id: capture.id,
      title: analysis?.title ?? capture.title ?? name,
      url: extractedUrl,
      creator: analysis?.creator,
      platform: analysis?.platform ?? _platformLabel(capture),
      summary: analysis?.summary ?? capture.text ?? 'A voice memo saved into NanyNany.',
      whyUseful: analysis?.whyUseful ?? 'You saved this recording because the idea or reference was worth keeping.',
      useWhen: analysis?.useWhen ?? 'Resurface when a project overlaps with what was discussed in this voice memo.',
      transcript: analysis?.transcript,
      type: analysis == null ? ResourceType.other : _resourceTypeFromName(analysis.resourceType),
      topics: analysis?.topics ?? const ['voice note'],
      technologies: analysis?.technologies ?? const [],
      savedAt: capture.capturedAt,
    );
    await ResourceStore.save(resource);

    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: name,
          bytes: bytes,
          contentType: capture.mimeType ?? _audioContentType(name),
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> _saveFile(MemoryCapture capture) async {
    final path = capture.localPath;
    if (path == null) return false;
    await ResourceStore.save(
      Resource(
        id: capture.id,
        title: capture.title ?? _fileName(path, fallback: 'Shared file'),
        platform: _platformLabel(capture),
        summary: capture.text ?? 'A file saved into NanyNany for future reference.',
        whyUseful: 'You chose to keep this for a future learning, planning, or building context.',
        useWhen: 'Resurface when a project or goal overlaps with this memory.',
        type: ResourceType.other,
        topics: [_topicLabel(capture)],
        savedAt: capture.capturedAt,
      ),
    );
    return true;
  }

  static String _platformLabel(MemoryCapture capture) => switch (capture.kind) {
        MemoryCaptureKind.email => 'Email',
        MemoryCaptureKind.calendar => 'Calendar',
        MemoryCaptureKind.message => 'Message',
        MemoryCaptureKind.audio => 'Voice memo',
        MemoryCaptureKind.image => 'Shared image',
        MemoryCaptureKind.video => 'Shared video',
        MemoryCaptureKind.file => 'Shared file',
        _ => 'Shared text',
      };

  static String _topicLabel(MemoryCapture capture) => switch (capture.kind) {
        MemoryCaptureKind.email => 'email',
        MemoryCaptureKind.calendar => 'calendar',
        MemoryCaptureKind.message => 'message',
        MemoryCaptureKind.video => 'video',
        MemoryCaptureKind.file => 'shared file',
        _ => 'shared text',
      };

  static ResourceType _resourceTypeFromName(String value) => ResourceType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => ResourceType.other,
      );

  static bool _isAudioPath(String path) => RegExp(
        r'\.(m4a|mp3|wav|ogg|opus|webm|aac|flac)$',
        caseSensitive: false,
      ).hasMatch(path.split('?').first);

  static String _audioContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) return 'audio/mp4';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'audio/ogg';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.aac')) return 'audio/aac';
    return 'audio/wav';
  }

  static String _imageContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/png';
  }

  static String? _firstUrl(String text) {
    final match = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return match.group(0)?.replaceAll(RegExp(r'[),.;]+$'), '');
  }

  static bool _alreadySaved(String url) =>
      ResourceStore.getAll().any((resource) => resource.url == url);

  static String _titleFromText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 70) return normalized;
    return '${normalized.substring(0, 67)}…';
  }

  static String _fileName(String path, {required String fallback}) {
    final segments = path.split(RegExp(r'[/\\]')).where((e) => e.isNotEmpty).toList();
    return segments.isEmpty ? fallback : segments.last;
  }
}
