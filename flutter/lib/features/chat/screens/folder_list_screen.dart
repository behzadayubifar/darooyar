import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/folder_providers.dart';
import '../models/folder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';

class FolderListScreen extends ConsumerWidget {
  const FolderListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('پوشه‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateFolderDialog(context, ref),
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هنوز پوشه‌ای ندارید',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('ایجاد پوشه جدید'),
                    onPressed: () => _showCreateFolderDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return FolderListItem(
                folder: folder,
                onTap: () {
                  ref.read(selectedFolderProvider.notifier).state = folder;
                  // Navigate back to the ChatListScreen
                  Navigator.of(context).pop();
                },
                onEdit: () => _showEditFolderDialog(context, ref, folder),
                onDelete: () => _showDeleteFolderDialog(context, ref, folder),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطا در بارگذاری پوشه‌ها: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(folderNotifierProvider.notifier).loadFolders();
                },
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    String? selectedColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ایجاد پوشه جدید'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'نام پوشه',
                    hintText: 'نام پوشه را وارد کنید',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('رنگ پوشه (اختیاری)'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorOption(
                        context,
                        '4A6FE5',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        'E53935',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        '43A047',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        'FFA000',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        '8E24AA',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = textController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(folderNotifierProvider.notifier).createFolder(
                          name,
                          color: selectedColor,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('ایجاد'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditFolderDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    final textController = TextEditingController(text: folder.name);
    String? selectedColor = folder.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ویرایش پوشه'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'نام پوشه',
                    hintText: 'نام جدید پوشه را وارد کنید',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('رنگ پوشه (اختیاری)'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorOption(
                        context,
                        '4A6FE5',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        'E53935',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        '43A047',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        'FFA000',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      _buildColorOption(
                        context,
                        '8E24AA',
                        selectedColor,
                        (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = textController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(folderNotifierProvider.notifier).updateFolder(
                          folder.id,
                          name,
                          color: selectedColor,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    String colorHex,
    String? selectedColor,
    Function(String) onColorSelected,
  ) {
    final color = Color(int.parse('FF$colorHex', radix: 16));
    final isSelected = selectedColor == colorHex;

    return GestureDetector(
      onTap: () => onColorSelected(colorHex),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  void _showDeleteFolderDialog(
      BuildContext context, WidgetRef ref, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پوشه'),
        content: Text(
            'آیا از حذف پوشه "${folder.name}" اطمینان دارید؟ گفتگوهای داخل پوشه حذف نمی‌شوند.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(folderNotifierProvider.notifier).deleteFolder(folder.id);
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class FolderListItem extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FolderListItem({
    Key? key,
    required this.folder,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folderColor = folder.getColor() ?? AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.folder,
          color: folderColor,
          size: 28,
        ),
        title: Text(folder.name),
        subtitle: Text('${folder.chatCount} گفتگو'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'ویرایش',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: 'حذف',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
