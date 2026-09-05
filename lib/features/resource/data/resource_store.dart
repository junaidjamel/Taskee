import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/domain/resource.dart';

class ResourceStore {
  static const boxName = 'resource_memory_resources';

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }

  static Box<Map> get box => Hive.box<Map>(boxName);

  static List<Resource> getAll() {
    final resources = box.values
        .map((value) => Resource.fromMap(Map<String, dynamic>.from(value)))
        .toList();
    resources.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return resources;
  }

  static Resource? getById(String id) {
    final value = box.get(id);
    if (value == null) return null;
    return Resource.fromMap(Map<String, dynamic>.from(value));
  }

  static Future<void> save(Resource resource) async {
    await box.put(resource.id, resource.toMap());
    await CloudSyncService.push(resource);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
    await CloudSyncService.remove(id);
  }

  static Future<int> syncNow() async {
    if (!CloudSyncService.isSignedIn) return getAll().length;

    final local = getAll();
    await CloudSyncService.pushAll(local);
    final remote = await CloudSyncService.pullAll();

    for (final resource in remote) {
      await box.put(resource.id, resource.toMap());
    }
    return getAll().length;
  }
}
