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
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _chatService.getChatMessages(_chatId);
      state = AsyncValue.data(messages);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendMessage(String content,
      {String contentType = 'text'}) async {
    try {
      final newMessage = await _chatService.createMessage(
        _chatId,
        content,
        'user',
        contentType: contentType,
      );
      if (newMessage != null) {
        state.whenData((messages) {
          state = AsyncValue.data([...messages, newMessage]);
        });
      } else {
        AppLogger.e('Failed to create message: returned null');
      }
    } catch (e) {
      AppLogger.e('Error sending message: $e');
      // Don't update state on error to preserve current list
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
