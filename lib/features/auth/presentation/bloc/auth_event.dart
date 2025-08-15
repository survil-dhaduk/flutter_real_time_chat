part of 'auth_bloc.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when authentication status changes
class AuthStatusChanged extends AuthEvent {
  final User? user;

  const AuthStatusChanged({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Event triggered when user requests to sign in
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event triggered when user requests to sign up
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}

/// Event triggered when user requests to sign out
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Event triggered to check current authentication status
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
