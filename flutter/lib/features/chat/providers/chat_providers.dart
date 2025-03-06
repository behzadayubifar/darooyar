import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../../../core/utils/logger.dart';
import 'folder_providers.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

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

      if (!mounted) return; // Check if the notifier is still mounted

      // Update the state with the new data
      state = AsyncValue.data(chats);

      // Log successful refresh
      AppLogger.i('Successfully refreshed ${chats.length} chats');
    } catch (e, stackTrace) {
      AppLogger.e('Error loading chats: $e');

      if (!mounted) return; // Check if the notifier is still mounted

      // Keep existing data if available, but mark as error
      final currentChats = state.valueOrNull ?? [];
      if (currentChats.isNotEmpty) {
        AppLogger.i(
            'Keeping ${currentChats.length} existing chats despite refresh error');
        // Keep existing data but mark as error
        state = AsyncValue.error(e, stackTrace);
      } else {
        // No existing data, set empty list
        state = AsyncValue.data([]);
      }
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
