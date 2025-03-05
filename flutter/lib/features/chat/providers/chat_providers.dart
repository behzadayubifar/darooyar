import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../../../core/utils/logger.dart';
import 'folder_providers.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>((ref) {
  return ChatListNotifier(ref.read(chatServiceProvider), ref);
});

final selectedChatProvider = StateProvider<Chat?>((ref) => null);

final chatLoadingProvider = StateProvider<bool>((ref) => false);

class ChatListNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final ChatService _chatService;
  final Ref _ref;

  ChatListNotifier(this._chatService, this._ref)
      : super(const AsyncValue.loading()) {
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      state = const AsyncValue.loading();
      final chats = await _chatService.getUserChats();
      state = AsyncValue.data(chats);
    } catch (e) {
      print('Error loading chats: $e');
      state = AsyncValue.data([]);
    }
  }

  Future<void> createChat(String title) async {
    try {
      final newChat = await _chatService.createChat(title);
      if (newChat != null) {
        state.whenData((chats) {
          state = AsyncValue.data([newChat, ...chats]);
        });
      } else {
        AppLogger.e('Failed to create chat: returned null');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      state.whenData((chats) {
        state =
            AsyncValue.data(chats.where((chat) => chat.id != chatId).toList());
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateChat(String chatId, {String? title, int? folderId}) async {
    try {
      final updatedChat = await _chatService.updateChat(chatId,
          title: title, folderId: folderId);
      if (updatedChat != null) {
        final currentChats = state.value ?? [];
        final updatedChats = currentChats.map((chat) {
          return chat.id == chatId ? updatedChat : chat;
        }).toList();
        state = AsyncValue.data(updatedChats);

        // If we're updating the folder, refresh the folder data to update chat counts
        if (folderId != null) {
          _ref.read(folderNotifierProvider.notifier).refreshFolders();
        }
      }
    } catch (e) {
      // Keep the current state but log the error
      AppLogger.e('Error updating chat: $e');
    }
  }
}
