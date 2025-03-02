import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/api_client.dart';
import '../../../../core/utils/database_service.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/entities/prescription_message_entity.dart';

part 'prescription_providers.g.dart';

// Service providers
@riverpod
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

@riverpod
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
}

// Repository provider
@riverpod
PrescriptionRepository prescriptionRepository(PrescriptionRepositoryRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  final databaseService = ref.watch(databaseServiceProvider);

  return PrescriptionRepository(
    apiClient: apiClient,
    databaseService: databaseService,
  );
}

// State providers
@riverpod
Future<List<PrescriptionEntity>> prescriptions(PrescriptionsRef ref) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  return repository.getAllPrescriptions();
}

@riverpod
class SelectedPrescriptionId extends _$SelectedPrescriptionId {
  @override
  String? build() => null;

  void select(String? id) {
    state = id;
  }
}

// Simple provider for controlling history panel visibility
final showHistoryPanelProvider = StateProvider<bool>((ref) => true);

@riverpod
Future<PrescriptionEntity?> selectedPrescription(
    SelectedPrescriptionRef ref) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescriptionId = ref.watch(selectedPrescriptionIdProvider);

  if (prescriptionId == null) {
    return null;
  }

  return repository.getPrescriptionById(prescriptionId);
}

@riverpod
Future<List<PrescriptionMessageEntity>> prescriptionMessages(
    PrescriptionMessagesRef ref, String prescriptionId) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  return repository.getMessagesByPrescriptionId(prescriptionId);
}

// Action providers
@riverpod
Future<PrescriptionEntity> createPrescriptionFromText(
    CreatePrescriptionFromTextRef ref,
    ({String text, String title}) params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescription =
      await repository.createPrescriptionFromText(params.text, params.title);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Set the newly created prescription as selected
  ref.read(selectedPrescriptionIdProvider.notifier).select(prescription.id);

  // Hide the history panel to show the chat
  ref.read(showHistoryPanelProvider.notifier).state = false;

  return prescription;
}

@riverpod
Future<PrescriptionEntity> createPrescriptionFromImage(
    CreatePrescriptionFromImageRef ref,
    ({File image, String title}) params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final prescription =
      await repository.createPrescriptionFromImage(params.image, params.title);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Set the newly created prescription as selected
  ref.read(selectedPrescriptionIdProvider.notifier).select(prescription.id);

  // Hide the history panel to show the chat
  ref.read(showHistoryPanelProvider.notifier).state = false;

  return prescription;
}

@riverpod
Future<PrescriptionMessageEntity> sendFollowUpMessage(
    SendFollowUpMessageRef ref,
    ({String prescriptionId, String message}) params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  final message = await repository.sendFollowUpMessage(
      params.prescriptionId, params.message);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(params.prescriptionId));

  return message;
}

@riverpod
Future<void> deletePrescription(
    DeletePrescriptionRef ref, String prescriptionId) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.deletePrescription(prescriptionId);

  // Refresh the prescriptions list
  ref.invalidate(prescriptionsProvider);

  // Clear the selected prescription if it was deleted
  final selectedId = ref.read(selectedPrescriptionIdProvider);
  if (selectedId == prescriptionId) {
    ref.read(selectedPrescriptionIdProvider.notifier).select(null);
  }
}

@riverpod
Future<void> deleteMessage(DeleteMessageRef ref,
    ({String messageId, String prescriptionId}) params) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.deleteMessage(params.messageId);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(params.prescriptionId));
}

@riverpod
Future<void> updateMessage(
    UpdateMessageRef ref, PrescriptionMessageEntity message) async {
  final repository = ref.watch(prescriptionRepositoryProvider);
  await repository.updateMessage(message);

  // Refresh the messages list
  ref.invalidate(prescriptionMessagesProvider(message.prescriptionId));
}
