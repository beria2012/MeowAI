import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/ml_service.dart';
import 'services/breed_data_service.dart';
import 'services/stats_service.dart';
import 'utils/theme.dart';
import 'utils/app_localizations.dart';

void main() async {
  print('🚀 Starting MeowAI app initialization...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter bindings initialized');
  
  // Setup error handling for production
  _setupErrorHandling();
  print('✅ Error handling setup complete');
  
  // Initialize Firebase (temporarily disabled for development)
  // TODO: Configure Firebase properly and uncomment the lines below
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  // Initialize Hive for local storage
  print('📦 Initializing Hive...');
  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 10));
    print('✅ Hive initialized');
  } catch (e) {
    print('⚠️ Hive initialization failed: $e, continuing anyway...');
  }
  
  // Initialize timezone data for notifications
  print('🕒 Initializing timezone data...');
  tz.initializeTimeZones();
  print('✅ Timezone data initialized');
  
  // Set preferred orientations
  print('📱 Setting device orientations...');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  print('✅ Device orientations set');
  
  // Optimize memory usage
  print('🧠 Optimizing memory usage...');
  _optimizeMemoryUsage();
  print('✅ Memory optimization complete');
  
  print('🎨 Starting app widget...');
  runApp(
    const ProviderScope(
      child: MeowAIApp(),
    ),
  );
  print('✅ App widget started');
  
  // Initialize services after app is running (non-blocking)
  print('⚙️ Initializing services in background...');
  _initializeServicesAsync();
}

/// Setup comprehensive error handling for production
void _setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, use default error handling
      FlutterError.presentError(details);
    } else {
      // In release mode, log error for analytics
      _logError(details.exception, details.stack);
    }
  };
  
  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      _logError(error, stack);
    }
    return true;
  };
}

/// Initialize services asynchronously in background (non-blocking)
void _initializeServicesAsync() {
  // Run in background without blocking UI
  Future.microtask(() async {
    await _initializeServices();
  });
}

/// Initialize all app services with error handling
Future<void> _initializeServices() async {
  try {
    print('  📢 Initializing notification service...');
    await NotificationService().initialize();
    print('  ✅ Notification service ready');
    
    print('  🗄️ Initializing database service...');
    await DatabaseService().initialize();
    print('  ✅ Database service ready');
    
    print('  📊 Initializing stats service...');
    await StatsService().initialize();
    print('  ✅ Stats service ready');
    
    print('  📚 Initializing breed data service...');
    await BreedDataService().initialize();
    print('  ✅ Breed data service ready');
    
    print('  🧠 Initializing ML service...');
    await MLService().initialize();
    print('  ✅ ML service ready');
    
    print('All services initialized successfully');
  } catch (e, stack) {
    print('❌ Error initializing services: $e');
    _logError(e, stack);
  }
}

/// Optimize memory usage for better performance
void _optimizeMemoryUsage() {
  // Set memory pressure callback
  SystemChannels.lifecycle.setMessageHandler((message) async {
    if (message == AppLifecycleState.paused.toString()) {
      // Clear image caches when app is paused
      imageCache.clear();
      imageCache.clearLiveImages();
    }
    return null;
  });
}

/// Log errors for analytics and crash reporting
void _logError(dynamic error, StackTrace? stack) {
  // In a real implementation, you would send this to:
  // - Firebase Crashlytics
  // - Sentry
  // - Your own analytics service
  print('ERROR: $error');
  if (stack != null) {
    print('STACK: $stack');
  }
}

class MeowAIApp extends ConsumerWidget {
  const MeowAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MeowAI',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('ru', ''), // Russian
        Locale('uk', ''), // Ukrainian
        Locale('zh', ''), // Chinese (Simplified)
        Locale('pt', ''), // Portuguese (Brazilian)
        Locale('de', ''), // German
        Locale('fr', ''), // French
        Locale('ja', ''), // Japanese
        Locale('ar', ''), // Arabic
        Locale('it', ''), // Italian
        Locale('ko', ''), // Korean
        Locale('tr', ''), // Turkish
        Locale('hi', ''), // Hindi
      ],
      
      // App entry point
      home: const SplashScreen(),
      
      // Routes configuration for navigation fallbacks
      routes: {
        '/home': (context) => const HomeScreen(),
        '/splash': (context) => const SplashScreen(),
        '/encyclopedia': (context) => const HomeScreen(), // Navigate to home screen with encyclopedia tab
      },
    );
  }
}