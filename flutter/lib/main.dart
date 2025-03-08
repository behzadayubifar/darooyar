import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive_size.dart';
import 'core/utils/logger.dart';
import 'features/prescription/presentation/providers/prescription_providers.dart';
import 'features/prescription/presentation/screens/splash_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/chat/services/chat_service.dart';
import 'features/subscription/screens/subscription_screen.dart';

// Flag to track if API endpoint discovery has been run
bool _apiEndpointDiscoveryRun = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger (disable in production)
  AppLogger.enable(true);
  AppLogger.i('Initializing app...');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AppLogger.d('Set preferred orientations');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  AppLogger.d('Set system UI overlay style');

  // Create a ProviderContainer to access providers before runApp
  final container = ProviderContainer();
  AppLogger.d('Created provider container');

  try {
    // Run migration service using the provider
    AppLogger.i('Starting message migration...');
    final migrationService = container.read(messageMigrationServiceProvider);
    await migrationService.migrateAIMessages();
    AppLogger.i('Message migration completed');
  } catch (e) {
    AppLogger.e('Error during migration: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both initialization and auth state
    final isInitialized = ref.watch(appInitializationProvider);
    final authState = ref.watch(authStateProvider);

    // Run API endpoint discovery when authenticated (only in debug mode)
    if (kDebugMode &&
        !_apiEndpointDiscoveryRun &&
        authState.valueOrNull != null) {
      _apiEndpointDiscoveryRun = true;
      debugPrint('User authenticated, running API endpoint discovery');
      // Use a microtask to avoid blocking the UI thread
      Future.microtask(() async {
        try {
          final chatService = ChatService();
          await chatService.discoverApiEndpoints();
        } catch (e) {
          debugPrint('API endpoint discovery error: $e');
          // Don't let discovery errors affect the main app flow
        }
      });
    }

    debugPrint(
        'Build called - Init state: ${isInitialized.value ?? false}, Auth state: ${authState.valueOrNull != null ? authState.valueOrNull!.email : 'Not logged in'}');

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ref.watch(themeModeProvider),
      initialRoute:
          '/splash', // Start with splash screen to handle initialization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      locale: const Locale('fa', 'IR'),
      onGenerateRoute: (settings) {
        // Check authentication state for protected routes
        final authState = ref.read(authStateProvider);
        final isAuthenticated =
            authState.hasValue && authState.valueOrNull != null;

        // Allow these routes regardless of auth state
        if (settings.name == '/login' ||
            settings.name == '/register' ||
            settings.name == '/splash') {
          return MaterialPageRoute(builder: (context) {
            switch (settings.name) {
              case '/login':
                return const LoginScreen();
              case '/register':
                return const RegisterScreen();
              case '/splash':
              default:
                return const SplashScreen();
            }
          });
        }

        // For all other routes, redirect to login if not authenticated
        if (!isAuthenticated) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }

        // User is authenticated, allow protected routes
        return MaterialPageRoute(builder: (context) {
          switch (settings.name) {
            case '/home':
              return const ChatListScreen();
            case '/settings':
              return SettingsScreen(user: authState.value!);
            case '/subscription':
              return const SubscriptionScreen();
            default:
              return const ChatListScreen();
          }
        });
      },
      builder: (context, child) {
        final fontSizeScale = ref.watch(fontSizeProvider);
        // Initialize ResponsiveSize here to ensure it's available throughout the app
        ResponsiveSize.init(context);
        return MediaQuery(
          // Apply the font size from settings
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontSizeScale),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
  }
}

// Provider to track app initialization
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Starting app initialization...');

    // Initialize database
    final databaseService = ref.read(databaseServiceProvider);
    await databaseService.db;

    // Verify database is properly initialized
    debugPrint('Database initialized successfully');

    // Initialize other services that depend on the database
    final repository = ref.read(prescriptionRepositoryProvider);
    await repository.getAllPrescriptions(); // Pre-fetch prescriptions
    debugPrint('Prescriptions pre-fetched');

    debugPrint('App initialization completed successfully');
    return true;
  } catch (e, stack) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stack');
    // Return true anyway to allow the app to continue
    // This prevents the app from getting stuck in initialization
    return true;
  }
});

// NOTE: authStateProvider and AuthStateNotifier have been removed from here
// They are now imported from features/auth/providers/auth_providers.dart
