import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder.dart';
import '../services/folder_service.dart';
import '../../../core/utils/logger.dart';

final folderServiceProvider = Provider<FolderService>((ref) {
  return FolderService();
});

final foldersProvider = FutureProvider<List<Folder>>((ref) async {
  final folderService = ref.watch(folderServiceProvider);
  return await folderService.getUserFolders();
});

final selectedFolderProvider = StateProvider<Folder?>((ref) => null);

class FolderNotifier extends StateNotifier<AsyncValue<List<Folder>>> {
  final FolderService _folderService;

  FolderNotifier(this._folderService) : super(const AsyncValue.loading()) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    state = const AsyncValue.loading();
    try {
      final folders = await _folderService.getUserFolders();
      state = AsyncValue.data(folders);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Explicitly refresh folder data to update chat counts
  Future<void> refreshFolders() async {
    try {
      AppLogger.i('Refreshing folders to update chat counts');
      final folders = await _folderService.refreshFolders();
      state = AsyncValue.data(folders);
      AppLogger.i('Folders refreshed successfully with updated chat counts');
    } catch (e) {
      AppLogger.e('Error refreshing folders: $e');
      // Keep the current state but log the error
    }
  }

  Future<void> createFolder(String name, {String? color}) async {
    try {
      final newFolder = await _folderService.createFolder(name, color: color);
      if (newFolder != null) {
        state = AsyncValue.data([...state.value ?? [], newFolder]);
      }
    } catch (e) {
      // Keep the current state but log the error
      print('Error creating folder: $e');
    }
  }

  Future<void> updateFolder(int id, String name, {String? color}) async {
    try {
      final updatedFolder =
          await _folderService.updateFolder(id, name, color: color);
      if (updatedFolder != null) {
        final currentFolders = state.value ?? [];
        final updatedFolders = currentFolders.map((folder) {
          return folder.id == id ? updatedFolder : folder;
        }).toList();
        state = AsyncValue.data(updatedFolders);
      }
    } catch (e) {
      // Keep the current state but log the error
      print('Error updating folder: $e');
    }
  }

  Future<void> deleteFolder(int id) async {
    try {
      final success = await _folderService.deleteFolder(id);
      if (success) {
        final currentFolders = state.value ?? [];
        final updatedFolders =
            currentFolders.where((folder) => folder.id != id).toList();
        state = AsyncValue.data(updatedFolders);
      }
    } catch (e) {
      // Keep the current state but log the error
      print('Error deleting folder: $e');
    }
  }
}

final folderNotifierProvider =
    StateNotifierProvider<FolderNotifier, AsyncValue<List<Folder>>>((ref) {
  final folderService = ref.watch(folderServiceProvider);
  return FolderNotifier(folderService);
});
