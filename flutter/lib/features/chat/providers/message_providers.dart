import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'chat_providers.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/message_migration_service.dart';
import '../../../core/utils/message_formatter.dart';
import '../../subscription/providers/subscription_provider.dart';
import 'dart:io';

final messageListProvider = StateNotifierProvider.family<MessageListNotifier,
    AsyncValue<List<Message>>, String>(
  (ref, chatId) =>
      MessageListNotifier(ref.read(chatServiceProvider), chatId, ref),
);

class MessageListNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatService _chatService;
  final String _chatId;
  final Ref _ref;

  MessageListNotifier(this._chatService, this._chatId, this._ref)
      : super(const AsyncValue.loading()) {
    AppLogger.i('Initializing MessageListNotifier for chat: $_chatId');
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      AppLogger.i('Loading messages for chat: $_chatId');
      state = const AsyncValue.loading();
      final messages = await _chatService.getChatMessages(_chatId);
      AppLogger.i('Loaded ${messages.length} messages for chat: $_chatId');
      state = AsyncValue.data(messages);
    } catch (e) {
      AppLogger.e('Error loading messages for chat $_chatId: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendMessage(String content,
      {String contentType = 'text'}) async {
    try {
      AppLogger.i('Sending message to chat $_chatId: $content');

      // Check if user has an active subscription plan
      final currentPlan = await _ref.read(currentPlanProvider.future);
      if (currentPlan == null) {
        throw Exception('برای ارسال پیام جدید نیاز به اشتراک فعال دارید');
      }

      // Add optimistic message for better UX
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempMessage = Message(
        id: tempId,
        content: content,
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: contentType,
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, tempMessage]);
      });

      final newMessage = await _chatService.createMessage(
        _chatId,
        content,
        'user',
        contentType: contentType,
      );

      if (newMessage != null) {
        state.whenData((messages) {
          final filteredMessages =
              messages.where((msg) => msg.id != tempId).toList();
          state = AsyncValue.data([...filteredMessages, newMessage]);
        });
        AppLogger.i('Message sent successfully to chat $_chatId');

        // Check if this is a prescription message that should trigger AI analysis
        final isPrescription = content.contains('نسخه:') ||
            content.contains('نسخه ') ||
            content.contains('دارو:') ||
            content.contains('دارو ') ||
            content.contains('قرص ') ||
            content.contains('کپسول ') ||
            content.contains('شربت ') ||
            content.contains('آمپول ') ||
            content.toLowerCase().contains('prescription:') ||
            content.toLowerCase().contains('rx:') ||
            content.toLowerCase().contains('medicine:');

        if (isPrescription) {
          // Add temporary "thinking" message
          final thinkingId =
              'thinking-${DateTime.now().millisecondsSinceEpoch}';
          final thinkingMessage = Message(
            id: thinkingId,
            content: 'در حال تحلیل نسخه...',
            role: 'assistant',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            contentType: 'thinking',
          );

          state.whenData((messages) {
            state = AsyncValue.data([...messages, thinkingMessage]);
          });

          // Poll for new messages to check for AI response
          _pollForAIResponse(thinkingId);
        }
      } else {
        // Replace the temporary message with an error message
        AppLogger.e('Failed to create message: Server returned null');
        state.whenData((messages) {
          final filteredMessages =
              messages.where((msg) => msg.id != tempId).toList();

          // Add an error message in place of the failed message
          final errorMessage = Message(
            id: 'error-${DateTime.now().millisecondsSinceEpoch}',
            content:
                'خطا در ارسال پیام: $content\nلطفا دوباره تلاش کنید یا با پشتیبانی تماس بگیرید.',
            role: 'system',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            contentType: 'error', // Use a special content type for errors
          );

          state = AsyncValue.data([...filteredMessages, errorMessage]);
        });
      }
    } catch (e) {
      AppLogger.e('Error sending message to chat $_chatId: $e');

      // Update the UI to show an error message
      state.whenData((messages) {
        // Find the temporary message
        final tempMessage = messages.lastWhere(
          (msg) => msg.role == 'user' && msg.content == content,
          orElse: () => Message(
            id: 'not-found',
            content: '',
            role: 'user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Replace it with an error message if found
        if (tempMessage.id != 'not-found') {
          final filteredMessages =
              messages.where((msg) => msg.id != tempMessage.id).toList();

          final errorMessage = Message(
            id: 'error-${DateTime.now().millisecondsSinceEpoch}',
            content: 'خطا در ارسال پیام. لطفا دوباره تلاش کنید.',
            role: 'system',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            contentType: 'error',
          );

          state = AsyncValue.data([...filteredMessages, errorMessage]);
        }
      });
    }
  }

  // Poll for new AI response after sending a prescription message
  Future<void> _pollForAIResponse(String thinkingMessageId) async {
    // Define polling parameters
    final int maxAttempts = 20; // افزایش تعداد تلاش‌ها از 12 به 20
    const Duration pollInterval =
        Duration(seconds: 5); // افزایش فاصله زمانی از 3 به 5 ثانیه
    int attempts = 0;
    bool aiResponseReceived = false;

    // Keep track of last message count to detect new messages
    int lastMessageCount = 0;
    state.whenData((messages) {
      lastMessageCount = messages.length;
    });

    AppLogger.i('Starting to poll for AI response with ID: $thinkingMessageId');
    AppLogger.d('Max attempts: $maxAttempts, Poll interval: $pollInterval');

    // First check if an assistant message already exists
    try {
      final messages = await _chatService.getChatMessages(_chatId);

      // Log all messages for debugging
      AppLogger.d('Current messages in chat:');
      for (final msg in messages) {
        AppLogger.d(
            'Message [${msg.id}] - Role: ${msg.role}, Type: ${msg.contentType}, Length: ${msg.content.length}');
      }

      final assistantMessages = messages
          .where((msg) =>
              msg.role == 'assistant' &&
              msg.contentType == 'text' &&
              !msg.isThinking &&
              !msg.isLoading)
          .toList();

      if (assistantMessages.isNotEmpty) {
        // Found existing assistant message
        AppLogger.i(
            'Found ${assistantMessages.length} existing assistant messages, no need to poll');

        // Get the most recent assistant message
        final latestAssistantMessage = assistantMessages
            .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);

        AppLogger.d(
            'Using assistant message: [ID: ${latestAssistantMessage.id}] Length: ${latestAssistantMessage.content.length} chars');

        // Migrate the message content if needed
        final migratedContent = MessageMigrationService.migrateAIMessage(
          latestAssistantMessage.content,
        );

        // Create a new message with the migrated content
        final migratedMessage = Message(
          id: latestAssistantMessage.id,
          content: migratedContent,
          role: latestAssistantMessage.role,
          createdAt: latestAssistantMessage.createdAt,
          updatedAt: latestAssistantMessage.updatedAt,
          contentType: latestAssistantMessage.contentType,
        );

        // Replace thinking message with actual AI response
        state.whenData((currentMessages) {
          final filteredMessages = currentMessages
              .where((msg) => msg.id != thinkingMessageId)
              .toList();

          state = AsyncValue.data([...filteredMessages, migratedMessage]);
          AppLogger.i('Replaced thinking message with actual AI response');
        });

        return; // No need to poll further
      }
    } catch (e) {
      AppLogger.e('Error checking for existing messages: $e');
      // Continue with polling as fallback
    }

    // Poll until AI response is received or max attempts reached
    while (!aiResponseReceived && attempts < maxAttempts) {
      try {
        AppLogger.d(
            'Polling for AI response, attempt ${attempts + 1}/$maxAttempts');
        await Future.delayed(pollInterval);

        // Fetch latest messages from server
        final messages = await _chatService.getChatMessages(_chatId);

        // Log all messages for debugging
        AppLogger.d('Messages after polling attempt ${attempts + 1}:');
        for (final msg in messages) {
          AppLogger.d(
              'Message [${msg.id}] - Role: ${msg.role}, Type: ${msg.contentType}, Length: ${msg.content.length}');
        }

        // Check for assistant messages first, regardless of count comparison
        final assistantMessages = messages
            .where((msg) =>
                msg.role == 'assistant' &&
                msg.contentType == 'text' &&
                !msg.isThinking &&
                !msg.isLoading)
            .toList();

        if (assistantMessages.isNotEmpty) {
          // Found new assistant message
          AppLogger.i('Found ${assistantMessages.length} assistant messages');

          for (final msg in assistantMessages) {
            AppLogger.d(
                'Assistant message: [ID: ${msg.id}] Length: ${msg.content.length} chars');
          }

          // Get the most recent assistant message
          final latestAssistantMessage = assistantMessages
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);

          // Migrate the message content if needed
          final migratedContent = MessageMigrationService.migrateAIMessage(
            latestAssistantMessage.content,
          );

          // Create a new message with the migrated content
          final migratedMessage = Message(
            id: latestAssistantMessage.id,
            content: migratedContent,
            role: latestAssistantMessage.role,
            createdAt: latestAssistantMessage.createdAt,
            updatedAt: latestAssistantMessage.updatedAt,
            contentType: latestAssistantMessage.contentType,
          );

          // Replace thinking message with actual AI response
          state.whenData((currentMessages) {
            final filteredMessages = currentMessages
                .where((msg) => msg.id != thinkingMessageId)
                .toList();

            state = AsyncValue.data([...filteredMessages, migratedMessage]);
          });

          aiResponseReceived = true;
          AppLogger.i(
              'AI response received after ${attempts + 1} polling attempts');
          break;
        }

        // Fallback to message count check
        else if (messages.length > lastMessageCount) {
          // New message(s) added, check if any are from assistant
          final newAssistantMessages = messages
              .where((msg) =>
                  msg.role == 'assistant' &&
                  msg.contentType == 'text' &&
                  !msg.isThinking &&
                  !msg.isLoading)
              .toList();

          if (newAssistantMessages.isNotEmpty) {
            AppLogger.d(
                'Found ${newAssistantMessages.length} assistant messages');

            // Migrate all new assistant messages
            final migratedMessages = newAssistantMessages.map((msg) {
              final migratedContent = MessageMigrationService.migrateAIMessage(
                msg.content,
              );

              return Message(
                id: msg.id,
                content: migratedContent,
                role: msg.role,
                createdAt: msg.createdAt,
                updatedAt: msg.updatedAt,
                contentType: msg.contentType,
              );
            }).toList();

            for (final msg in migratedMessages) {
              AppLogger.d(
                  'Migrated assistant message: [ID: ${msg.id}] Length: ${msg.content.length} chars');
            }

            // Replace thinking message with actual AI response
            state.whenData((currentMessages) {
              final filteredMessages = currentMessages
                  .where((msg) => msg.id != thinkingMessageId)
                  .toList();

              state =
                  AsyncValue.data([...filteredMessages, ...migratedMessages]);
            });

            aiResponseReceived = true;
            AppLogger.i(
                'AI response received after ${attempts + 1} polling attempts');
            break;
          }
        }

        attempts++;
        lastMessageCount =
            messages.length; // Update message count for next iteration
      } catch (e) {
        AppLogger.e('Error polling for AI response: $e');
        attempts++;
      }
    }

    // If no AI response received after max attempts, replace thinking message with error
    if (!aiResponseReceived) {
      AppLogger.w(
          'No AI response received after $maxAttempts polling attempts');
      state.whenData((messages) {
        final filteredMessages =
            messages.where((msg) => msg.id != thinkingMessageId).toList();

        final timeoutMessage = Message(
          id: 'timeout-${DateTime.now().millisecondsSinceEpoch}',
          content:
              'متأسفانه در دریافت پاسخ تحلیل نسخه خطایی رخ داد. لطفا دوباره تلاش کنید یا نسخه را به صورت متنی وارد کنید.',
          role: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          contentType: 'error',
        );

        state = AsyncValue.data([...filteredMessages, timeoutMessage]);
      });

      // Try to force refresh messages from server one last time
      try {
        await _chatService.getChatMessages(_chatId);
      } catch (e) {
        AppLogger.e('Error in final attempt to refresh messages: $e');
      }
    }
  }

  Future<void> sendImageMessage(String imagePath) async {
    try {
      AppLogger.i('Sending image message from path: $imagePath');

      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.e('Image file does not exist: $imagePath');
        throw Exception('Image file does not exist');
      }

      // Log file size
      final fileSize = await file.length();
      AppLogger.d(
          'Image file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Add a temporary loading message
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempMessage = Message(
        id: tempId,
        content: 'در حال آپلود تصویر...',
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: 'loading',
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, tempMessage]);
      });

      // Upload the image
      AppLogger.d('Uploading image to server...');
      final newMessage =
          await _chatService.uploadImageMessage(_chatId, imagePath);

      // Replace the temporary message with the actual one or remove it if failed
      state.whenData((messages) {
        final updatedMessages =
            messages.where((msg) => msg.id != tempId).toList();
        if (newMessage != null) {
          updatedMessages.add(newMessage);
          AppLogger.i(
              'Image uploaded successfully with message ID: ${newMessage.id}');
        }
        state = AsyncValue.data(updatedMessages);
      });

      if (newMessage == null) {
        AppLogger.e('Failed to upload image: returned null');

        // Add error message
        state.whenData((messages) {
          final errorMessage = Message(
            id: 'error-${DateTime.now().millisecondsSinceEpoch}',
            content: 'خطا در آپلود تصویر. لطفا دوباره تلاش کنید.',
            role: 'system',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            contentType: 'error',
          );

          state = AsyncValue.data([...messages, errorMessage]);
        });
      } else {
        // Add temporary "thinking" message for prescription image analysis
        final thinkingId = 'thinking-${DateTime.now().millisecondsSinceEpoch}';
        final thinkingMessage = Message(
          id: thinkingId,
          content: 'در حال تحلیل نسخه تصویری...',
          role: 'assistant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          contentType: 'thinking',
        );

        state.whenData((messages) {
          state = AsyncValue.data([...messages, thinkingMessage]);
        });

        AppLogger.i('Added thinking message with ID: $thinkingId');
        AppLogger.i('Starting to poll for AI response...');

        // Poll for new messages to check for AI response
        _pollForAIResponse(thinkingId);
      }
    } catch (e) {
      AppLogger.e('Error sending image message: $e');
      // Remove the temporary message on error
      state.whenData((messages) {
        final updatedMessages =
            messages.where((msg) => msg.contentType != 'loading').toList();

        // Add error message
        final errorMessage = Message(
          id: 'error-${DateTime.now().millisecondsSinceEpoch}',
          content:
              'خطا در ارسال تصویر: ${e.toString()}. لطفا دوباره تلاش کنید.',
          role: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          contentType: 'error',
        );

        state = AsyncValue.data([...updatedMessages, errorMessage]);
      });
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(_chatId, messageId);
      state.whenData((messages) {
        state = AsyncValue.data(
            messages.where((msg) => msg.id != messageId).toList());
      });
    } catch (e) {
      AppLogger.e('Error deleting message: $e');
      // Don't update state on error to preserve current list
    }
  }
}
