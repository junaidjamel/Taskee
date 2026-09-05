import 'package:flutter_test/flutter_test.dart';
import 'package:taskee/features/resource/domain/resource.dart';

void main() {
  group('Resource', () {
    test('round-trips through map serialization', () {
      final savedAt = DateTime.utc(2026, 8, 17, 6);
      final resource = Resource(
        id: '1',
        title: 'Luau Inventory Tutorial',
        url: 'https://example.com/luau-inventory',
        creator: 'Example Creator',
        platform: 'YouTube',
        summary: 'Build a Roblox inventory system with Luau.',
        whyUseful: 'Useful for learning inventory architecture.',
        useWhen: 'When building a Roblox inventory system.',
        type: ResourceType.video,
        status: ResourceStatus.saved,
        topics: const ['inventory', 'roblox'],
        technologies: const ['luau'],
        savedAt: savedAt,
      );

      final restored = Resource.fromMap(resource.toMap());

      expect(restored.id, resource.id);
      expect(restored.title, resource.title);
      expect(restored.url, resource.url);
      expect(restored.creator, resource.creator);
      expect(restored.platform, resource.platform);
      expect(restored.type, ResourceType.video);
      expect(restored.status, ResourceStatus.saved);
      expect(restored.topics, ['inventory', 'roblox']);
      expect(restored.technologies, ['luau']);
      expect(restored.savedAt, savedAt);
    });

    test('searchableText includes contextual fields', () {
      final resource = Resource(
        id: '2',
        title: 'Roblox DataStore Guide',
        creator: 'Junaid',
        platform: 'YouTube',
        summary: 'Saving player data.',
        whyUseful: 'Persistent game progress.',
        useWhen: 'Building save systems.',
        topics: const ['inventory'],
        technologies: const ['Luau'],
        savedAt: DateTime.utc(2026, 8, 17),
      );

      expect(resource.searchableText, contains('roblox datastore guide'));
      expect(resource.searchableText, contains('junaid'));
      expect(resource.searchableText, contains('inventory'));
      expect(resource.searchableText, contains('luau'));
      expect(resource.searchableText, contains('building save systems'));
    });
  });
}
