import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/providers/folder_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/providers/subscription_providers.dart';

// Provider for the auth service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provider for the current user (null if not authenticated)
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  return AuthStateNotifier(ref.watch(authServiceProvider), ref);
});

// Auth state notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final Ref _ref;
  bool _isCheckingAuth = false;

  AuthStateNotifier(this._authService, this._ref)
      : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (_isCheckingAuth) {
      debugPrint('AuthStateNotifier: Auth check already in progress, skipping');
      return;
    }

    _isCheckingAuth = true;
    debugPrint('AuthStateNotifier: Checking authentication state...');

    try {
      // First check if we have a valid token without making a network request
      final hasValidToken = await _authService.hasValidToken();
      debugPrint('AuthStateNotifier: Has valid token: $hasValidToken');

      if (!hasValidToken) {
        debugPrint(
            'AuthStateNotifier: No valid token found, setting auth state to null');
        if (mounted) {
          state = const AsyncValue.data(null);
        }
        _isCheckingAuth = false;
        return;
      }

      // If we have a valid token, try to get the current user
      debugPrint(
          'AuthStateNotifier: Token appears valid, retrieving user data...');
      final user = await _authService.getCurrentUser();
      debugPrint(
          'AuthStateNotifier: User data retrieval result: ${user != null ? 'User found' : 'No user found'}');

      if (user != null && mounted) {
        debugPrint(
            'AuthStateNotifier: Setting authenticated state with user: ${user.email}');
        state = AsyncValue.data(user);
      } else if (mounted) {
        // If getCurrentUser returns null despite having a valid token,
        // there might be a server issue or token validation problem
        debugPrint(
            'AuthStateNotifier: Token appeared valid but user data could not be retrieved');
        state = const AsyncValue.data(null);

        // Try to clear the invalid token
        debugPrint('AuthStateNotifier: Logging out due to invalid token');
        await _authService.logout();
      }
    } catch (e) {
      debugPrint('AuthStateNotifier: Error during authentication check: $e');
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);

        // After a brief delay, set to not authenticated on error
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            state = const AsyncValue.data(null);
          }
        });
      }

      // Try to clear any potentially invalid token
      debugPrint('AuthStateNotifier: Logging out due to error');
      await _authService.logout();
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authService.logout();

      // Clear all cached data by invalidating providers
      // This ensures that when a new user logs in, they don't see the previous user's data
      // Invalidate chat-related providers
      _ref.invalidate(chatListProvider);

      // Invalidate any other user-specific data providers
      _ref.invalidate(currentPlanProvider);
      _ref.invalidate(activeSubscriptionsProvider);
      _ref.invalidate(userSubscriptionsProvider);

      // Invalidate folder providers if they exist
      try {
        _ref.invalidate(folderNotifierProvider);
      } catch (e) {
        // Ignore if provider doesn't exist
        debugPrint('Could not invalidate folder provider: $e');
      }

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshUser() async {
    debugPrint('AuthStateNotifier: Refreshing user data');
    if (!_isCheckingAuth) {
      _checkAuth();
    } else {
      debugPrint(
          'AuthStateNotifier: Auth check already in progress, refresh queued');
      // Queue a refresh after current check completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isCheckingAuth) {
          _checkAuth();
        }
      });
    }
  }

  // Update user data in the state
  void updateUserData(User updatedUser) {
    debugPrint(
        'AuthStateNotifier: Updating user data for: ${updatedUser.email}');
    state = AsyncValue.data(updatedUser);
  }
}

// Convenience provider for auth status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.hasValue && authState.valueOrNull != null;
});
