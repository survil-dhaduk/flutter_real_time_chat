import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_real_time_chat/injection/injection.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'navigation_service.dart';

/// Splash screen that handles initial authentication check
class SplashPage extends StatefulWidget {
  final String? deepLink;

  const SplashPage({
    super.key,
    this.deepLink,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
    
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // User is authenticated, handle initial route or deep link
          NavigationService.handleInitialRoute(true, deepLink: widget.deepLink);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          // User is not authenticated
          if (widget.deepLink != null && widget.deepLink!.isNotEmpty) {
            // Store deep link for after authentication
            // For now, just navigate to login
            NavigationService.navigateToLogin();
          } else {
            NavigationService.navigateToLogin();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // App title
              Text(
                'Real-Time Chat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Connect instantly with friends',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              LoadingIndicator(
                message: 'Initializing...',
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
