import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taskee/features/resource/domain/resource.dart';

class ResourceDraft {
  const ResourceDraft({
    required this.title,
    required this.summary,
    required this.whyUseful,
    required this.useWhen,
    required this.type,
    required this.platform,
    this.creator,
    this.thumbnail,
    this.topics = const [],
    this.technologies = const [],
  });

  final String title;
  final String summary;
  final String whyUseful;
  final String useWhen;
  final ResourceType type;
  final String platform;
  final String? creator;
  final String? thumbnail;
  final List<String> topics;
  final List<String> technologies;

  ResourceDraft copyWith({
    String? summary,
    String? whyUseful,
    String? useWhen,
    List<String>? topics,
    List<String>? technologies,
  }) {
    return ResourceDraft(
      title: title,
      summary: summary ?? this.summary,
      whyUseful: whyUseful ?? this.whyUseful,
      useWhen: useWhen ?? this.useWhen,
      type: type,
      platform: platform,
      creator: creator,
      thumbnail: thumbnail,
      topics: topics ?? this.topics,
      technologies: technologies ?? this.technologies,
    );
  }
}

class ResourceEnrichmentService {
  static const String _aiUrl = String.fromEnvironment('RESOURCE_MEMORY_AI_URL');

  static Future<ResourceDraft> enrich(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a valid http or https link.');
    }

    final base = await _deterministic(uri);
    if (_aiUrl.isEmpty) return base;

    try {
      return await _enrichWithAi(uri, base);
    } catch (_) {
      return base;
    }
  }

  static Future<ResourceDraft> _deterministic(Uri uri) async {
    final host = uri.host.toLowerCase().replaceFirst('www.', '');

    if (host == 'youtu.be' || host.endsWith('youtube.com')) {
      return _youtube(uri);
    }
    if (host.endsWith('github.com')) {
      return _github(uri);
    }
    if (host.endsWith('threads.com') || host.endsWith('threads.net')) {
      return _threads(uri);
    }

    return _generic(uri);
  }

  static Future<ResourceDraft> _enrichWithAi(Uri uri, ResourceDraft base) async {
    final response = await http
        .post(
          Uri.parse(_aiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'url': uri.toString(),
            'title': base.title,
            'creator': base.creator,
            'platform': base.platform,
            'summary': base.summary,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI enrichment failed');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return base.copyWith(
      summary: json['summary'] as String?,
      whyUseful: json['whyUseful'] as String?,
      useWhen: json['useWhen'] as String?,
      topics: List<String>.from(json['topics'] as List? ?? base.topics),
      technologies:
          List<String>.from(json['technologies'] as List? ?? base.technologies),
    );
  }

  static Future<ResourceDraft> _youtube(Uri uri) async {
    try {
      final endpoint = Uri.https('www.youtube.com', '/oembed', {
        'url': uri.toString(),
        'format': 'json',
      });
      final response =
          await http.get(endpoint).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final title = json['title'] as String? ?? 'YouTube video';
        final creator = json['author_name'] as String?;
        return ResourceDraft(
          title: title,
          creator: creator,
          thumbnail: json['thumbnail_url'] as String?,
          platform: 'YouTube',
          type: ResourceType.video,
          summary: 'A saved YouTube resource about ${_topicFromTitle(title)}.',
          whyUseful:
              'Useful as a visual walkthrough or reference while learning and building.',
          useWhen:
              'Resurface when a project or learning goal overlaps with ${_topicFromTitle(title)}.',
          topics: _keywords(title),
          technologies: _technologyKeywords(title),
        );
      }
    } catch (_) {}

    return const ResourceDraft(
      title: 'YouTube video',
      platform: 'YouTube',
      type: ResourceType.video,
      summary: 'A saved YouTube learning resource.',
      whyUseful: 'Useful as a visual tutorial or reference.',
      useWhen: 'Resurface when the current project matches this video topic.',
    );
  }

  static Future<ResourceDraft> _github(Uri uri) async {
    final parts = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final owner = parts[0];
      final repo = parts[1];
      try {
        final endpoint = Uri.https('api.github.com', '/repos/$owner/$repo');
        final response = await http.get(endpoint, headers: {
          'Accept': 'application/vnd.github+json',
        }).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final description = (json['description'] as String?)?.trim();
          final language = json['language'] as String?;
          final topics = List<String>.from(json['topics'] as List? ?? const []);
          return ResourceDraft(
            title: json['name'] as String? ?? repo,
            creator: owner,
            platform: 'GitHub',
            type: ResourceType.github,
            summary: description?.isNotEmpty == true
                ? description!
                : 'GitHub repository by $owner.',
            whyUseful:
                'Useful as working code, implementation reference, or a starting point for a related build.',
            useWhen:
                'Resurface when building something related to ${description ?? repo}.',
            topics: topics,
            technologies: [if (language != null) language],
          );
        }
      } catch (_) {}

      return ResourceDraft(
        title: repo,
        creator: owner,
        platform: 'GitHub',
        type: ResourceType.github,
        summary: 'GitHub repository by $owner.',
        whyUseful: 'Useful as source code or implementation reference.',
        useWhen: 'Resurface when a project overlaps with this repository.',
      );
    }

    return const ResourceDraft(
      title: 'GitHub resource',
      platform: 'GitHub',
      type: ResourceType.github,
      summary: 'Saved GitHub resource.',
      whyUseful: 'Useful for source code and implementation reference.',
      useWhen: 'Resurface during related coding work.',
    );
  }

  static Future<ResourceDraft> _threads(Uri uri) async {
    final handle = uri.pathSegments.isEmpty
        ? null
        : uri.pathSegments.firstWhere(
            (segment) => segment.startsWith('@'),
            orElse: () => '',
          );
    final creator = handle == null || handle.isEmpty ? null : handle.substring(1);
    return ResourceDraft(
      title:
          creator == null ? 'Threads resource' : 'Threads resource from @$creator',
      creator: creator,
      platform: 'Threads',
      type: ResourceType.article,
      summary: 'A saved Threads post or creator resource.',
      whyUseful:
          'Useful for practical ideas, recommendations, tools, or advice worth revisiting.',
      useWhen:
          'Resurface when the current project matches the ideas or tools you saved from this source.',
      topics: const ['creator resource'],
    );
  }

  static Future<ResourceDraft> _generic(Uri uri) async {
    final host = uri.host.replaceFirst('www.', '');
    final label = host.split('.').first;
    final pretty = label.isEmpty
        ? host
        : '${label[0].toUpperCase()}${label.substring(1)}';
    return ResourceDraft(
      title: pretty,
      platform: host,
      type: ResourceType.website,
      summary: 'Saved website from $host.',
      whyUseful:
          'A resource you chose to keep for future learning or project work.',
      useWhen:
          'Resurface when a current task overlaps with this site or its purpose.',
      topics: _keywords(uri.path.replaceAll('/', ' ')),
    );
  }

  static String _topicFromTitle(String title) {
    final words =
        title.split(RegExp(r'\s+')).where((w) => w.length > 2).take(6);
    return words.join(' ');
  }

  static List<String> _keywords(String text) {
    const stop = {
      'the',
      'and',
      'for',
      'with',
      'this',
      'that',
      'from',
      'your',
      'you',
      'how',
      'what',
      'into',
      'using',
      'use',
      'app',
      'video',
      'tutorial'
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9+#. ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stop.contains(w))
        .toSet()
        .take(8)
        .toList();
  }

  static List<String> _technologyKeywords(String text) {
    const tech = [
      'flutter',
      'dart',
      'luau',
      'lua',
      'roblox',
      'react',
      'next.js',
      'nextjs',
      'typescript',
      'javascript',
      'python',
      'swift',
      'kotlin',
      'css',
      'html',
      'firebase',
      'supabase',
      'hive'
    ];
    final lower = text.toLowerCase();
    return tech.where((item) => lower.contains(item)).toList();
  }
}
