import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/chat.dart';
import '../providers/message_providers.dart';
import '../widgets/message_input.dart';
import '../widgets/message_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/chat_providers.dart';

/// صفحه نمایش گفتگو با پزشک هوش مصنوعی
class ChatScreen extends HookConsumerWidget {
  final String chatId;

  const ChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // کنترل‌کننده اسکرول برای لیست پیام‌ها
    final scrollController = useState(ScrollController());

    // وضعیت پردازش نسخه
    final isPrescriptionProcessing = useState(false);

    // وضعیت لیست پیام‌ها
    final messagesState = ref.watch(messageListProvider(chatId));

    // اطلاعات چت
    final chat = useState<Chat?>(null);

    // دریافت اطلاعات چت از سرور
    useEffect(() {
      // دریافت اطلاعات چت
      ref.read(chatServiceProvider).getUserChats().then((chats) {
        final currentChat = chats.firstWhere(
          (c) => c.id == chatId,
          orElse: () => Chat(
            id: chatId,
            title: 'گفتگوی جدید',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messages: [],
          ),
        );
        chat.value = currentChat;
      });

      // اسکرول به انتهای لیست در اولین بارگذاری
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(scrollController.value);
      });

      return null;
    }, [chatId]);

    // اسکرول به انتهای لیست در هر تغییر پیام‌ها
    useEffect(() {
      messagesState.whenData((messages) {
        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(scrollController.value);
          });
        }
      });

      return null;
    }, [messagesState]);

    // تنظیم عنوان چت
    final chatTitle = chat.value?.title ?? 'گفتگو';

    // نمایش کامپوننت‌های صفحه
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatTitle,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPrescriptionProcessing.value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'در حال تحلیل نسخه',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // نمایش اطلاعات چت
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // لیست پیام‌ها
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'هنوز پیامی ارسال نشده است',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return MessageList(
                  messages: messages,
                  chatId: chatId,
                  scrollController: scrollController.value,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
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
                      'خطا در بارگذاری پیام‌ها:\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final _ = ref.refresh(messageListProvider(chatId));
                      },
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ورودی پیام
          if (chat.value != null)
            MessageInput(
              chat: chat.value!,
              scrollController: scrollController.value,
              isPrescriptionProcessing: isPrescriptionProcessing.value,
              onPrescriptionProcessingChanged: (value) {
                isPrescriptionProcessing.value = value;
              },
              onMessageSent: () {
                // عملیات پس از ارسال پیام
              },
            ),
        ],
      ),
    );
  }

  // اسکرول به انتهای لیست پیام‌ها
  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
