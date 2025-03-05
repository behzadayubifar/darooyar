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

  Future<void> sendMessage(String content) async {
    try {
      final newMessage = await _chatService.createMessage(
        _chatId,
        content,
        'user',
      );
      if (newMessage != null) {
        state.whenData((messages) {
          state = AsyncValue.data([...messages, newMessage]);
        });
      } else {
        AppLogger.e('Failed to create message: returned null');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
