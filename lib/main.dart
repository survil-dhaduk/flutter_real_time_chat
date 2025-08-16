import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'injection/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/user_context_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/cache_service.dart';
import 'core/widgets/error_boundary.dart';
import 'core/routing/routing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize cache service
  await sl<CacheService>().initialize();

  // Initialize user context service
  await sl<UserContextService>().initialize();

  // Initialize connectivity service
  sl<ConnectivityService>().initialize();

  // Initialize deep link handling
  DeepLinkHandler.initialize();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Global Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Verify dependencies are initialized (for debugging)
  // print('Dependencies initialized: ${areDependenciesInitialized()}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        title: 'Real-Time Chat',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        navigatorKey: NavigationService.navigatorKey,
        navigatorObservers: [AppRouteObserver()],
        initialRoute: RouteNames.splash,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
