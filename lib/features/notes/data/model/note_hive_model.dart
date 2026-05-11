import 'package:hive/hive.dart';

part 'note_hive_model.g.dart';

@HiveType(typeId: 2)
class NoteHiveModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String note;

  @HiveField(2)
  final DateTime createdAt;

  const NoteHiveModel({
    required this.id,
    required this.note,
    required this.createdAt,
  });
}
