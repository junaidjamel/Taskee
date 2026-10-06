import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/features/commitment/domain/commitment.dart';

class CommitmentStore {
  static const boxName = 'resource_memory_commitments';

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map>(boxName);
  }

  static Box<Map> get box => Hive.box<Map>(boxName);

  static List<Commitment> getAll() {
    final items = box.values.map((v) => Commitment.fromMap(Map<String, dynamic>.from(v))).toList();
    items.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return items;
  }

  static Future<void> save(Commitment item) => box.put(item.id, item.toMap());
  static Future<void> remove(String id) => box.delete(id);
}
