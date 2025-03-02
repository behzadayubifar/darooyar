import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/prescription/domain/entities/prescription_entity.dart';
import '../../features/prescription/domain/entities/prescription_message_entity.dart';

class DatabaseService {
  // Singleton instance
  static DatabaseService? _instance;

  // Shared database future
  late Future<Isar> db;

  // Factory constructor to return the singleton instance
  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  // Private constructor for singleton
  DatabaseService._internal() {
    db = openDatabase();
  }

  Future<Isar> openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();

    // Check if an instance is already open for this directory
    if (Isar.instanceNames.isNotEmpty) {
      try {
        // Try to get the existing instance
        return Future.value(Isar.getInstance()!);
      } catch (e) {
        // If getting the instance fails, open a new one
      }
    }

    return Isar.open(
      [PrescriptionEntitySchema, PrescriptionMessageEntitySchema],
      directory: dir.path,
    );
  }

  // Prescription methods
  Future<List<PrescriptionEntity>> getAllPrescriptions() async {
    final isar = await db;
    return isar.prescriptionEntitys.where().sortByCreatedAtDesc().findAll();
  }

  Future<PrescriptionEntity?> getPrescriptionById(String id) async {
    final isar = await db;
    return isar.prescriptionEntitys.filter().idEqualTo(id).findFirst();
  }

  Future<void> savePrescription(PrescriptionEntity prescription) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.prescriptionEntitys.put(prescription);
    });
  }

  Future<void> deletePrescription(String id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final prescription =
          await isar.prescriptionEntitys.filter().idEqualTo(id).findFirst();
      if (prescription != null) {
        await isar.prescriptionEntitys.delete(prescription.isarId);

        // Delete all messages associated with this prescription
        final messages = await isar.prescriptionMessageEntitys
            .filter()
            .prescriptionIdEqualTo(id)
            .findAll();

        for (final message in messages) {
          await isar.prescriptionMessageEntitys.delete(message.isarId);
        }
      }
    });
  }

  // Message methods
  Future<List<PrescriptionMessageEntity>> getMessagesByPrescriptionId(
      String prescriptionId) async {
    final isar = await db;
    return isar.prescriptionMessageEntitys
        .filter()
        .prescriptionIdEqualTo(prescriptionId)
        .sortByTimestamp()
        .findAll();
  }

  Future<void> saveMessage(PrescriptionMessageEntity message) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.prescriptionMessageEntitys.put(message);
    });
  }

  Future<void> deleteMessage(String id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.prescriptionMessageEntitys
          .filter()
          .idEqualTo(id)
          .findFirst();
      if (message != null) {
        await isar.prescriptionMessageEntitys.delete(message.isarId);
      }
    });
  }

  Future<void> updateMessage(PrescriptionMessageEntity message) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.prescriptionMessageEntitys.put(message);
    });
  }
}
