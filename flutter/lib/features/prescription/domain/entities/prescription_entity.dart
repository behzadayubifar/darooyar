import 'package:isar/isar.dart';

part 'prescription_entity.g.dart';

@collection
class PrescriptionEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late String title;
  late DateTime createdAt;
  late String? imageUrl;

  PrescriptionEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    this.imageUrl,
  });
}
