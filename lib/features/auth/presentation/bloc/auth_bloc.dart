import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/mixins/error_handling_mixin.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for managing authentication state and events
class AuthBloc extends Bloc<AuthEvent, AuthState>
    with ErrorHandlingMixin<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository;

  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthRepository authRepository,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // Listen to authentication state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthStatusChanged(user: user)),
    );

    // Check initial authentication status
    add(const CheckAuthStatus());
  }

  /// Handles authentication status changes from the repository stream
  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handles sign in requests
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await executeWithErrorHandling(
        () => _signInUseCase(
          SignInParams(
            email: event.email,
            password: event.password,
          ),
        ),
        operationName: 'sign_in',
        enableRetry: false, // Don't retry auth operations automatically
      );

      result.fold(
        (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
        (user) => emit(AuthAuthenticated(user: user)),
      );
    } catch (error, stackTrace) {
      handleError(error, stackTrace, operation: 'sign_in');
    }
  }

  /// Handles sign up requests
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await executeWithErrorHandling(
        () => _signUpUseCase(
          SignUpParams(
            email: event.email,
            password: event.password,
            displayName: event.displayName,
          ),
        ),
        operationName: 'sign_up',
        enableRetry: false, // Don't retry auth operations automatically
      );

      result.fold(
        (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
        (user) => emit(AuthAuthenticated(user: user)),
      );
    } catch (error, stackTrace) {
      handleError(error, stackTrace, operation: 'sign_up');
    }
  }

  /// Handles sign out requests
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await executeWithErrorHandling(
        () => _signOutUseCase(),
        operationName: 'sign_out',
        enableRetry: false, // Don't retry auth operations automatically
      );

      result.fold(
        (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
        (_) => emit(const AuthUnauthenticated()),
      );
    } catch (error, stackTrace) {
      handleError(error, stackTrace, operation: 'sign_out');
    }
  }

  /// Handles checking current authentication status
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) {
        // If getting current user fails, assume unauthenticated
        // Don't emit error state for initial check
        if (failure is! AuthFailure) {
          emit(AuthError(message: _mapFailureToMessage(failure)));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  /// Maps failure types to user-friendly error messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure) {
      case ValidationFailure _:
        return failure.message;
      case AuthFailure _:
        return failure.message;
      case NetworkFailure _:
        return 'Network error. Please check your connection and try again.';
      case ServerFailure _:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void emitErrorState(
    Failure failure, {
    String? operation,
    AuthState? previousState,
  }) {
    emit(AuthError(message: _mapFailureToMessage(failure)));
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
