import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../../features/auth/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  bool _isInitialized = false;
  bool _safetyTimeoutCancelled = false;

  @override
  void initState() {
    super.initState();
    // Delay the check slightly to ensure providers are ready
    Future.delayed(const Duration(milliseconds: 100), _checkInitialization);

    // Safety timeout - only if something goes wrong with auth state
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_hasNavigated && !_safetyTimeoutCancelled) {
        debugPrint('Safety timeout reached, navigating to login');
        _navigateToLogin();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth state changes
    if (_isInitialized) {
      _checkAuthState();
    }
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _safetyTimeoutCancelled = true;
    debugPrint('Navigating to HomeScreen...');
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _safetyTimeoutCancelled = true;
    debugPrint('Navigating to LoginScreen...');
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _checkInitialization() {
    if (!mounted) return;

    debugPrint('Checking initialization and auth state...');
    final initializationState = ref.read(appInitializationProvider);

    // Add a try-catch block to handle any potential errors
    try {
      initializationState.whenData((initialized) {
        debugPrint('Initialization state: $initialized');
        if (initialized) {
          setState(() {
            _isInitialized = true;
          });
          _checkAuthState();
        } else {
          debugPrint('Initialization failed');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize app. Please try again.'),
            ),
          );
          // Still navigate to login even if initialization fails
          _navigateToLogin();
        }
      });
    } catch (e) {
      debugPrint('Error in _checkInitialization: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _checkAuthState() {
    if (!mounted || _hasNavigated) return;

    final authState = ref.read(authStateProvider);

    try {
      // Check if auth state is still loading
      if (authState is AsyncLoading) {
        debugPrint('Auth state is still loading, waiting...');
        // Schedule another check after a short delay
        Future.delayed(const Duration(milliseconds: 500), _checkAuthState);
        return;
      }

      // Check for auth state value
      authState.whenData((user) {
        debugPrint(
            'Auth state check result: ${user != null ? "User found" : "No user"}');
        if (!mounted) return;

        if (user != null) {
          // Cancel safety timeout since we have a valid user
          _safetyTimeoutCancelled = true;
          _navigateToHome();
        } else {
          // Only navigate to login if we're sure the user is not authenticated
          if (!authState.isLoading) {
            _navigateToLogin();
          }
        }
      });
    } catch (e) {
      debugPrint('Error processing auth state: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both initialization and auth state
    final initState = ref.watch(appInitializationProvider);
    final authState = ref.watch(authStateProvider);

    // Check auth state whenever it changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialized && !_hasNavigated) {
        _checkAuthState();
      }

      // Cancel safety timeout and navigate to home if user is authenticated
      if (authState.hasValue && authState.valueOrNull != null) {
        debugPrint(
            'User authenticated in post frame callback, cancelling safety timeout');
        _safetyTimeoutCancelled = true;
        if (!_hasNavigated) {
          _navigateToHome();
        }
      }
    });

    debugPrint(
        'Build called - Init state: ${initState.value}, Auth state: ${authState.value?.email ?? "Not logged in"}');

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // App name
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // App description
            Text(
              'دستیار هوشمند نسخه‌های دارویی',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
