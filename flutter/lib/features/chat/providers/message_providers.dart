import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'chat_providers.dart';
import '../../../core/utils/logger.dart';

final messageListProvider = StateNotifierProvider.family<MessageListNotifier,
    AsyncValue<List<Message>>, String>(
  (ref, chatId) => MessageListNotifier(ref.read(chatServiceProvider), chatId),
);

class MessageListNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatService _chatService;
  final String _chatId;

  MessageListNotifier(this._chatService, this._chatId)
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
    final int maxAttempts = 8; // Maximum number of attempts
    const Duration pollInterval = Duration(seconds: 2); // Time between polls
    int attempts = 0;
    bool aiResponseReceived = false;

    // Keep track of last message count to detect new messages
    int lastMessageCount = 0;
    state.whenData((messages) {
      lastMessageCount = messages.length;
    });

    // Poll until AI response is received or max attempts reached
    while (!aiResponseReceived && attempts < maxAttempts) {
      try {
        AppLogger.d(
            'Polling for AI response, attempt ${attempts + 1}/$maxAttempts');
        await Future.delayed(pollInterval);

        // Fetch latest messages from server
        final messages = await _chatService.getChatMessages(_chatId);

        // Check if we have more messages now than before
        if (messages.length > lastMessageCount) {
          // Find any message from the assistant
          final newAssistantMessages =
              messages.where((msg) => msg.role == 'assistant').toList();

          if (newAssistantMessages.isNotEmpty) {
            AppLogger.i(
                'Found ${newAssistantMessages.length} assistant messages');

            // Replace thinking message with actual AI response
            state.whenData((currentMessages) {
              final filteredMessages = currentMessages
                  .where((msg) => msg.id != thinkingMessageId)
                  .toList();

              state = AsyncValue.data(
                  [...filteredMessages, ...newAssistantMessages]);
            });

            aiResponseReceived = true;
            AppLogger.i(
                'AI response received after ${attempts + 1} polling attempts');
            break;
          }
        }

        attempts++;
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
              'متأسفانه در دریافت پاسخ تحلیل نسخه خطایی رخ داد. لطفا دوباره تلاش کنید.',
          role: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          contentType: 'error',
        );

        state = AsyncValue.data([...filteredMessages, timeoutMessage]);
      });
    }
  }

  Future<void> sendImageMessage(String imagePath) async {
    try {
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
      final newMessage =
          await _chatService.uploadImageMessage(_chatId, imagePath);

      // Replace the temporary message with the actual one or remove it if failed
      state.whenData((messages) {
        final updatedMessages =
            messages.where((msg) => msg.id != tempId).toList();
        if (newMessage != null) {
          updatedMessages.add(newMessage);
        }
        state = AsyncValue.data(updatedMessages);
      });

      if (newMessage == null) {
        AppLogger.e('Failed to upload image: returned null');
      }
    } catch (e) {
      AppLogger.e('Error sending image message: $e');
      // Remove the temporary message on error
      state.whenData((messages) {
        final updatedMessages =
            messages.where((msg) => msg.contentType != 'loading').toList();
        state = AsyncValue.data(updatedMessages);
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
