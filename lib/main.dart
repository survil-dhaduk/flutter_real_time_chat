import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'injection/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/user_context_service.dart';
import 'core/routing/routing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize user context service
  await sl<UserContextService>().initialize();

  // Verify dependencies are initialized (for debugging)
  // print('Dependencies initialized: ${areDependenciesInitialized()}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Chat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
