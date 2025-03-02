import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/api_client.dart';
import '../../../../core/utils/database_service.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/entities/prescription_message_entity.dart';

class PrescriptionRepository {
  final ApiClient _apiClient;
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  PrescriptionRepository({
    required ApiClient apiClient,
    required DatabaseService databaseService,
  })  : _apiClient = apiClient,
        _databaseService = databaseService;

  // Prescription methods
  Future<List<PrescriptionEntity>> getAllPrescriptions() async {
    return _databaseService.getAllPrescriptions();
  }

  Future<PrescriptionEntity?> getPrescriptionById(String id) async {
    return _databaseService.getPrescriptionById(id);
  }

  Future<void> deletePrescription(String id) async {
    await _databaseService.deletePrescription(id);
  }

  // Message methods
  Future<List<PrescriptionMessageEntity>> getMessagesByPrescriptionId(
      String prescriptionId) async {
    return _databaseService.getMessagesByPrescriptionId(prescriptionId);
  }

  Future<void> deleteMessage(String id) async {
    await _databaseService.deleteMessage(id);
  }

  Future<void> updateMessage(PrescriptionMessageEntity message) async {
    await _databaseService.updateMessage(message);
  }

  // Analysis methods
  Future<PrescriptionEntity> createPrescriptionFromText(
      String text, String title) async {
    // Create a new prescription
    final prescriptionId = _uuid.v4();
    final prescription = PrescriptionEntity(
      id: prescriptionId,
      title: title,
      createdAt: DateTime.now(),
    );

    await _databaseService.savePrescription(prescription);

    // Create user message
    final userMessageId = _uuid.v4();
    final userMessage = PrescriptionMessageEntity(
      id: userMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.user,
      content: text,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(userMessage);

    // Analyze the prescription
    final response = await _apiClient.analyzeAIPrescription(text);

    // Create AI response message
    final aiMessageId = _uuid.v4();
    final aiMessage = PrescriptionMessageEntity(
      id: aiMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.ai,
      content: response['analysis'] ?? AppStrings.noAnalysisAvailable,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(aiMessage);

    return prescription;
  }

  Future<PrescriptionEntity> createPrescriptionFromImage(
      File image, String title) async {
    // Create a new prescription
    final prescriptionId = _uuid.v4();
    final prescription = PrescriptionEntity(
      id: prescriptionId,
      title: title,
      createdAt: DateTime.now(),
      imageUrl: image.path,
    );

    await _databaseService.savePrescription(prescription);

    // Create user message
    final userMessageId = _uuid.v4();
    final userMessage = PrescriptionMessageEntity(
      id: userMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.user,
      content: AppStrings.imagePrescription,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(userMessage);

    // Analyze the prescription
    final response = await _apiClient.analyzePrescriptionImage(image);

    // Create AI response message
    final aiMessageId = _uuid.v4();
    final aiMessage = PrescriptionMessageEntity(
      id: aiMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.ai,
      content: response['analysis'] ?? AppStrings.noAnalysisAvailable,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(aiMessage);

    return prescription;
  }

  Future<PrescriptionMessageEntity> sendFollowUpMessage(
      String prescriptionId, String message) async {
    // Create user message
    final userMessageId = _uuid.v4();
    final userMessage = PrescriptionMessageEntity(
      id: userMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.user,
      content: message,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(userMessage);

    // Send to API for analysis
    final response = await _apiClient.analyzeAIPrescription(message);

    // Create AI response message
    final aiMessageId = _uuid.v4();
    final aiMessage = PrescriptionMessageEntity(
      id: aiMessageId,
      prescriptionId: prescriptionId,
      type: MessageType.ai,
      content: response['analysis'] ?? AppStrings.noAnalysisAvailable,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(aiMessage);

    return aiMessage;
  }
}
