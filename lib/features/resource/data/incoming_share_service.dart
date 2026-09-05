import 'package:cross_file/cross_file.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/data/resource_enrichment_service.dart';
import 'package:taskee/features/resource/data/resource_link_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';

class IncomingShareService {
  static Future<int> saveSharedItems(List<SharedMediaFile> items) async {
    var saved = 0;
    for (final item in items) {
      if (await _saveItem(item)) saved++;
    }
    return saved;
  }

  static Future<bool> _saveItem(SharedMediaFile item) async {
    switch (item.type) {
      case SharedMediaType.url:
      case SharedMediaType.text:
        return _saveTextOrUrl(item.path, item.message);
      case SharedMediaType.image:
        return _saveImage(item);
      case SharedMediaType.video:
      case SharedMediaType.file:
        if (_isAudioPath(item.path)) return _saveAudio(item);
        return _saveFile(item);
    }
  }

  static Future<bool> _saveTextOrUrl(String raw, String? message) async {
    final text = [raw, message].whereType<String>().join(' ').trim();
    if (text.isEmpty) return false;

    final url = _firstUrl(text);
    if (url != null) {
      if (_alreadySaved(url)) return false;
      final draft = await ResourceEnrichmentService.enrich(url);
      final now = DateTime.now();
      await ResourceStore.save(
        Resource(
          id: now.microsecondsSinceEpoch.toString(),
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
          savedAt: now,
        ),
      );
      return true;
    }

    final now = DateTime.now();
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: _titleFromText(text),
        platform: 'Shared text',
        summary: text,
        whyUseful: 'You shared this because it contained an idea, explanation, or reference worth keeping.',
        useWhen: 'Resurface when a project or learning goal overlaps with this note.',
        type: ResourceType.article,
        topics: const ['shared text'],
        savedAt: now,
      ),
    );
    return true;
  }

  static Future<bool> _saveImage(SharedMediaFile item) async {
    final name = _fileName(item.path, fallback: 'Shared screenshot');
    final bytes = await XFile(item.path).readAsBytes();
    if (bytes.isEmpty) return false;

    ImageResourceAnalysis? analysis;
    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        analysis = await CloudSyncService.analyzeImage(
          bytes: bytes,
          contentType: _imageContentType(name),
        );
      } catch (_) {
        // The image still saves if understanding is unavailable.
      }
    }

    final now = DateTime.now();
    final extractedUrl = analysis?.url == null
        ? null
        : ResourceLinkService.normalize(analysis!.url)?.toString();
    var resource = Resource(
      id: now.microsecondsSinceEpoch.toString(),
      title: analysis?.title ?? name,
      url: extractedUrl,
      creator: analysis?.creator,
      platform: analysis?.platform ?? 'Shared image',
      thumbnail: item.path,
      summary: analysis?.summary ??
          (item.message?.trim().isNotEmpty == true
              ? item.message!.trim()
              : 'An image or screenshot shared into Resource Memory.'),
      whyUseful: analysis?.whyUseful ??
          'Useful as a visual reference you wanted Future You to keep.',
      useWhen: analysis?.useWhen ??
          'Resurface when the current project overlaps with the subject of this image.',
      type: analysis == null
          ? ResourceType.screenshot
          : _resourceTypeFromName(analysis.resourceType),
      topics: analysis?.topics ?? const ['screenshot', 'visual reference'],
      technologies: analysis?.technologies ?? const [],
      savedAt: now,
    );
    await ResourceStore.save(resource);

    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: name,
          bytes: bytes,
          contentType: _imageContentType(name),
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> _saveAudio(SharedMediaFile item) async {
    final name = _fileName(item.path, fallback: 'Shared voice memo');
    final bytes = await XFile(item.path).readAsBytes();
    if (bytes.isEmpty) return false;

    AudioResourceAnalysis? analysis;
    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        analysis = await CloudSyncService.analyzeAudio(
          bytes: bytes,
          contentType: _audioContentType(name),
        );
      } catch (_) {
        // The voice memo still saves with local fallback metadata.
      }
    }

    final now = DateTime.now();
    final extractedUrl = analysis?.url == null
        ? null
        : ResourceLinkService.normalize(analysis!.url)?.toString();
    var resource = Resource(
      id: now.microsecondsSinceEpoch.toString(),
      title: analysis?.title ?? name,
      url: extractedUrl,
      creator: analysis?.creator,
      platform: analysis?.platform ?? 'Shared voice memo',
      summary: analysis?.summary ?? 'A voice memo shared into Resource Memory.',
      whyUseful: analysis?.whyUseful ??
          'You shared this recording because the idea or reference was worth keeping.',
      useWhen: analysis?.useWhen ??
          'Resurface when a project overlaps with what was discussed in this voice memo.',
      transcript: analysis?.transcript,
      type: analysis == null
          ? ResourceType.other
          : _resourceTypeFromName(analysis.resourceType),
      topics: analysis?.topics ?? const ['voice note'],
      technologies: analysis?.technologies ?? const [],
      savedAt: now,
    );
    await ResourceStore.save(resource);

    if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
      try {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: name,
          bytes: bytes,
          contentType: _audioContentType(name),
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> _saveFile(SharedMediaFile item) async {
    final now = DateTime.now();
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: _fileName(item.path, fallback: 'Shared file'),
        platform: 'Shared file',
        summary: 'A file shared into Resource Memory for future reference.',
        whyUseful: 'You chose to keep this file for a future learning or building context.',
        useWhen: 'Resurface when a project or learning goal overlaps with this file.',
        type: ResourceType.other,
        topics: const ['shared file'],
        savedAt: now,
      ),
    );
    return true;
  }

  static ResourceType _resourceTypeFromName(String value) {
    return ResourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ResourceType.other,
    );
  }

  static bool _isAudioPath(String path) {
    return RegExp(r'\.(m4a|mp3|wav|ogg|opus|webm|aac|flac)$', caseSensitive: false)
        .hasMatch(path.split('?').first);
  }

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

  static bool _alreadySaved(String url) {
    return ResourceStore.getAll().any((resource) => resource.url == url);
  }

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
