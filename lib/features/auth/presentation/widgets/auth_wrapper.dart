import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/auth_bloc.dart';
import '../pages/login_page.dart';

/// Widget that wraps the app and handles authentication state
class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: LoadingIndicator(
                message: 'Initializing...',
              ),
            ),
          );
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: LoadingIndicator(
                message: 'Loading...',
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return authenticatedChild;
        } else {
          // AuthUnauthenticated or AuthError
          return const LoginPage();
        }
      },
    );
  }
}
