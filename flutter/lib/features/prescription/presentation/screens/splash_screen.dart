import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import 'home_screen.dart';
import '../../../auth/screens/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay the check slightly to ensure providers are ready
    Future.delayed(const Duration(milliseconds: 100), _checkInitialization);

    // Add a timeout to ensure we don't get stuck on the splash screen
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('Splash screen timeout reached, navigating to login');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  void _checkInitialization() {
    if (!mounted) return;

    debugPrint('Checking initialization and auth state...');
    final initializationState = ref.read(appInitializationProvider);
    final authState = ref.read(authStateProvider);

    // Add a try-catch block to handle any potential errors
    try {
      initializationState.whenData((initialized) {
        debugPrint('Initialization state: $initialized');
        if (initialized) {
          try {
            authState.whenData((user) {
              debugPrint('Auth state: ${user?.email ?? "Not logged in"}');
              if (!mounted) return;

              if (user != null) {
                debugPrint('Navigating to HomeScreen...');
                Navigator.of(context).pushReplacementNamed('/home');
              } else {
                debugPrint('Navigating to LoginScreen...');
                Navigator.of(context).pushReplacementNamed('/login');
              }
            });
          } catch (e) {
            debugPrint('Error processing auth state: $e');
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        } else {
          debugPrint('Initialization failed');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize app. Please try again.'),
            ),
          );
          // Still navigate to login even if initialization fails
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    } catch (e) {
      debugPrint('Error in _checkInitialization: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both initialization and auth state
    final initState = ref.watch(appInitializationProvider);
    final authState = ref.watch(authStateProvider);

    debugPrint(
        'Build called - Init state: ${initState.value}, Auth state: ${authState.value?.email ?? "Not logged in"}');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
