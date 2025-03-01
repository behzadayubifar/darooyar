import 'package:isar/isar.dart';

part 'prescription_message_entity.g.dart';

enum MessageType { user, ai }

@collection
class PrescriptionMessageEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String prescriptionId;

  @Enumerated(EnumType.name)
  late MessageType type;

  late String content;
  late DateTime timestamp;

  PrescriptionMessageEntity({
    required this.id,
    required this.prescriptionId,
    required this.type,
    required this.content,
    required this.timestamp,
  });
}
