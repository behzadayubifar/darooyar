import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/api_client.dart';
import '../../../../core/utils/database_service.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/entities/prescription_message_entity.dart';

// Service providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Repository provider
final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final databaseService = ref.watch(databaseServiceProvider);

  return PrescriptionRepository(
    apiClient: apiClient,
    databaseService: databaseService,
  );
});

// State providers
final prescriptionsProvider =
    FutureProvider<List<PrescriptionEntity>>((ref) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  return repository.getAllPrescriptions();
});

final selectedPrescriptionIdProvider = StateProvider<String?>((ref) => null);

final selectedPrescriptionProvider =
    FutureProvider<PrescriptionEntity?>((ref) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescriptionId = ref.watch(selectedPrescriptionIdProvider);

  if (prescriptionId == null) {
    return null;
  }

  return repository.getPrescriptionById(prescriptionId);
});

final prescriptionMessagesProvider =
    FutureProvider.family<List<PrescriptionMessageEntity>, String>(
        (ref, prescriptionId) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  return repository.getMessagesByPrescriptionId(prescriptionId);
});

// Action providers
final createPrescriptionFromTextProvider =
    FutureProvider.family<PrescriptionEntity, ({String text, String title})>(
        (ref, params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescription =
      await repository.createPrescriptionFromText(params.text, params.title);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Set the newly created prescription as selected
  ref.read(selectedPrescriptionIdProvider.notifier).state = prescription.id;

  return prescription;
});

final createPrescriptionFromImageProvider =
    FutureProvider.family<PrescriptionEntity, ({File image, String title})>(
        (ref, params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescription =
      await repository.createPrescriptionFromImage(params.image, params.title);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Set the newly created prescription as selected
  ref.read(selectedPrescriptionIdProvider.notifier).state = prescription.id;

  return prescription;
});

final sendFollowUpMessageProvider = FutureProvider.family<
    PrescriptionMessageEntity,
    ({String prescriptionId, String message})>((ref, params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final message = await repository.sendFollowUpMessage(
      params.prescriptionId, params.message);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(params.prescriptionId));

  return message;
});

final deletePrescriptionProvider =
    FutureProvider.family<void, String>((ref, prescriptionId) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.deletePrescription(prescriptionId);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Clear the selected prescription if it was deleted
  final selectedId = ref.read(selectedPrescriptionIdProvider);
  if (selectedId == prescriptionId) {
    ref.read(selectedPrescriptionIdProvider.notifier).state = null;
  }
});

final deleteMessageProvider =
    FutureProvider.family<void, ({String messageId, String prescriptionId})>(
        (ref, params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.deleteMessage(params.messageId);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(params.prescriptionId));
});

final updateMessageProvider =
    FutureProvider.family<void, PrescriptionMessageEntity>(
        (ref, message) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.updateMessage(message);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(message.prescriptionId));
});
