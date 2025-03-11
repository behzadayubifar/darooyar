import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../providers/chat_providers.dart';
import '../providers/folder_providers.dart';
import '../models/chat.dart';
import 'chat_screen.dart';
import 'folder_list_screen.dart';
import '../../auth/providers/auth_providers.dart';

// This is the original ConsumerWidget version that is referenced in main.dart
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Redirect to the stateful version
    return const ChatListScreenWithRefresh();
  }
}

// This is the new ConsumerStatefulWidget version with refresh functionality
class ChatListScreenWithRefresh extends ConsumerStatefulWidget {
  const ChatListScreenWithRefresh({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreenWithRefresh> createState() =>
      _ChatListScreenWithRefreshState();
}

class _ChatListScreenWithRefreshState
    extends ConsumerState<ChatListScreenWithRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // مقداردهی اولیه - فقط برای به‌روزرسانی‌های دستی
    _lastRefreshTime = DateTime.now();

    // Refresh chat list when screen is first shown (فقط یک بار هنگام شروع)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChatList();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // هیچ کاری انجام نده - به‌روزرسانی خودکار غیرفعال شد
    // به‌روزرسانی فقط زمانی انجام می‌شود که کاربر صراحتاً درخواست کند (با pull-to-refresh)
  }

  // متغیرهای مورد نیاز - فقط برای به‌روزرسانی‌های دستی استفاده می‌شود
  DateTime _lastRefreshTime = DateTime.now();

  Future<void> _refreshChatList() async {
    // Check if user is authenticated before refreshing
    final authState = ref.read(authStateProvider);
    if (authState.hasValue && authState.valueOrNull != null) {
      // به‌روزرسانی زمان آخرین به‌روزرسانی
      _lastRefreshTime = DateTime.now();

      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('در حال بارگذاری گفتگوها...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await ref.read(chatListProvider.notifier).loadChats();

      // Provide feedback on completion
      if (mounted) {
        // Check the state to see if there was an error
        final state = ref.read(chatListProvider);
        if (state is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در بارگذاری گفتگوها. لطفاً دوباره تلاش کنید.'),
              backgroundColor: AppTheme.errorColor,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('گفتگوها با موفقیت بارگذاری شدند.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatListProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);
    final foldersAsync = ref.watch(folderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: selectedFolder != null
            ? Text('پوشه: ${selectedFolder.name}')
            : const Text('تاریخچه گفتگوها'),
        leading: selectedFolder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedFolderProvider.notifier).state = null;
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FolderListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              final authState = ref.read(authStateProvider);
              if (authState.valueOrNull == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لطفا ابتدا وارد حساب کاربری خود شوید'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChatList,
        child: chatsAsync.when(
          data: (chats) {
            // Filter chats by selected folder if needed
            final filteredChats = selectedFolder != null
                ? chats
                    .where((chat) => chat.folderId == selectedFolder.id)
                    .toList()
                : chats;

            if (filteredChats.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/empty_chat.json',
                            width: 200,
                            height: 200,
                            repeat: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedFolder != null
                                ? 'این پوشه خالی است'
                                : 'هنوز گفتگویی ندارید',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFolder != null
                                ? 'برای افزودن گفتگو به این پوشه، یک گفتگو ایجاد کنید یا از منوی گفتگوهای موجود استفاده کنید'
                                : 'برای شروع گفتگو روی دکمه + کلیک کنید',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];

                // Find folder color if chat is in a folder
                Color folderColor = AppTheme.primaryColor;
                if (chat.folderId != null) {
                  // Get the folder from the folders list
                  final folders = foldersAsync.valueOrNull ?? [];
                  if (folders.isNotEmpty) {
                    final folder = folders.firstWhere(
                      (f) => f.id == chat.folderId,
                      orElse: () => folders.first,
                    );

                    // Use the folder's color if available
                    if (folder.getColor() != null) {
                      folderColor = folder.getColor()!;
                    }
                  }
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: chat.folderId != null
                        ? Icon(Icons.folder, color: folderColor)
                        : const Icon(Icons.chat_outlined),
                    title: Text(chat.title),
                    subtitle: Text(
                      'ایجاد شده در ${chat.createdAt.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'تغییر پوشه',
                          onPressed: () {
                            _showFolderSelectionDialog(context, ref, chat);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'حذف گفتگو',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف گفتگو'),
                                content: const Text(
                                    'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('انصراف'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ref
                                          .read(chatListProvider.notifier)
                                          .deleteChat(chat.id);
                                    },
                                    child: const Text(
                                      'حذف',
                                      style:
                                          TextStyle(color: AppTheme.errorColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedChatProvider.notifier).state = chat;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chat: chat),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'خطا در دریافت گفتگوها:\n${error.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(chatListProvider.notifier).loadChats(),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a debug log to verify the button is being clicked
          AppLogger.i('New chat button clicked');

          // Show dialog to create a new chat
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent dismissing by tapping outside
            builder: (BuildContext dialogContext) {
              final titleController = TextEditingController();
              return AlertDialog(
                title: const Text('گفتگوی جدید'),
                content: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان گفتگو',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true, // Automatically focus the text field
                  onSubmitted: (value) {
                    // Handle Enter key press
                    if (value.isNotEmpty) {
                      Navigator.pop(dialogContext);
                      _createNewChat(context, ref, value);
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('انصراف'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        Navigator.pop(dialogContext);
                        _createNewChat(context, ref, titleController.text);
                      }
                    },
                    child: const Text('ایجاد'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'گفتگوی جدید',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper method to create a new chat
  Future<void> _createNewChat(
      BuildContext context, WidgetRef ref, String title) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال ایجاد گفتگو...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create the chat and wait for it to complete
      await ref.read(chatListProvider.notifier).createChat(title);

      // Get the newly created chat
      final chats = ref.read(chatListProvider).value;
      if (chats != null && chats.isNotEmpty) {
        // Find the most recently created chat (should be the first one)
        final newChat = chats.first;

        // Set as selected chat
        ref.read(selectedChatProvider.notifier).state = newChat;

        // Navigate to the chat screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: newChat),
            ),
          );
        }
      }
    } catch (error) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'خرید اشتراک',
              onPressed: () {
                // Navigate to subscription screen
                Navigator.pushNamed(context, '/subscription');
              },
            ),
          ),
        );
      }
    }
  }

  void _showFolderSelectionDialog(BuildContext context, WidgetRef ref, chat) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final foldersAsync = ref.watch(folderNotifierProvider);

            return AlertDialog(
              title: const Text('انتخاب پوشه'),
              content: SizedBox(
                width: double.maxFinite,
                child: foldersAsync.when(
                  data: (folders) {
                    if (folders.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('هنوز پوشه‌ای ایجاد نکرده‌اید.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCreateFolderDialog(context, ref, chat);
                            },
                            child: const Text('ایجاد پوشه جدید'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Option to remove from folder
                        ListTile(
                          leading: const Icon(Icons.folder_off),
                          title: const Text('بدون پوشه'),
                          onTap: () {
                            Navigator.pop(context);
                            ref.read(chatListProvider.notifier).updateChat(
                                  chat.id,
                                  title: chat.title,
                                  folderId: null,
                                );
                          },
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: folders.length,
                            itemBuilder: (context, index) {
                              final folder = folders[index];
                              final isSelected = chat.folderId == folder.id;

                              return ListTile(
                                leading: const Icon(Icons.folder),
                                title: Text(folder.name),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (!isSelected) {
                                    ref
                                        .read(chatListProvider.notifier)
                                        .updateChat(
                                          chat.id,
                                          title: chat.title,
                                          folderId: folder.id,
                                        );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('خطا در بارگذاری پوشه‌ها: $error'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateFolderDialog(context, ref, chat);
                  },
                  child: const Text('ایجاد پوشه جدید'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref, chat) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد پوشه جدید'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'نام پوشه',
            hintText: 'نام پوشه را وارد کنید',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);

                // Create the folder
                await ref
                    .read(folderNotifierProvider.notifier)
                    .createFolder(name);

                // Get the newly created folder
                final folders =
                    await ref.read(folderServiceProvider).getUserFolders();
                if (folders.isNotEmpty) {
                  // Find the folder we just created (should be the last one)
                  final newFolder = folders.firstWhere(
                    (folder) => folder.name == name,
                    orElse: () => folders.last,
                  );

                  // Move the chat to this folder
                  ref.read(chatListProvider.notifier).updateChat(
                        chat.id,
                        title: chat.title,
                        folderId: newFolder.id,
                      );
                }
              }
            },
            child: const Text('ایجاد و انتقال'),
          ),
        ],
      ),
    );
  }
}
