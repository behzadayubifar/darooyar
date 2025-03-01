import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/prescription_providers.dart';

class NewPrescriptionScreen extends HookConsumerWidget {
  const NewPrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final textController = useTextEditingController();
    final selectedImage = useState<File?>(null);
    final isLoading = useState(false);
    final activeTab = useState(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.newPrescription),
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: AppStrings.prescriptionTitle,
                      hintText: AppStrings.enterPrescriptionTitle,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab selector
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          context: context,
                          title: AppStrings.text,
                          icon: Icons.text_fields,
                          isSelected: activeTab.value == 0,
                          onTap: () => activeTab.value = 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTabButton(
                          context: context,
                          title: AppStrings.image,
                          icon: Icons.image,
                          isSelected: activeTab.value == 1,
                          onTap: () => activeTab.value = 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content based on selected tab
                  Expanded(
                    child: activeTab.value == 0
                        ? _buildTextInput(textController)
                        : _buildImageInput(selectedImage, context),
                  ),

                  // Submit button
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppStrings.pleaseEnterTitle)),
                        );
                        return;
                      }

                      if (activeTab.value == 0) {
                        final text = textController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    AppStrings.pleaseEnterPrescriptionText)),
                          );
                          return;
                        }

                        isLoading.value = true;
                        try {
                          await ref.read(createPrescriptionFromTextProvider(
                              (text: text, title: title)).future);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          isLoading.value = false;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${AppStrings.errorGeneric}: ${e.toString()}')),
                            );
                          }
                        }
                      } else {
                        final image = selectedImage.value;
                        if (image == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppStrings.pleaseSelectImage)),
                          );
                          return;
                        }

                        isLoading.value = true;
                        try {
                          await ref.read(createPrescriptionFromImageProvider(
                              (image: image, title: title)).future);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          isLoading.value = false;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${AppStrings.errorGeneric}: ${e.toString()}')),
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(AppStrings.analyzeButtonText),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: AppStrings.enterPrescriptionText,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildImageInput(
      ValueNotifier<File?> selectedImage, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: selectedImage.value == null
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: const Center(
                    child: Text(
                      AppStrings.noPrescriptionSelectedMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          selectedImage.value!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            selectedImage.value = null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.camera);

                  if (pickedFile != null) {
                    selectedImage.value = File(pickedFile.path);
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(AppStrings.takePicture),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    selectedImage.value = File(pickedFile.path);
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: Text(AppStrings.selectFromGallery),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
