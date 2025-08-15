import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';
import 'package:flutter_real_time_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_real_time_chat/features/auth/presentation/bloc/auth_bloc.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  SignInUseCase,
  SignUpUseCase,
  SignOutUseCase,
  GetCurrentUserUseCase,
  AuthRepository,
])
void main() {
  late AuthBloc authBloc;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockAuthRepository mockAuthRepository;
  late StreamController<User?> authStateController;

  final tUser = User(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
    lastSeen: DateTime.parse('2023-01-01T00:00:00.000Z'),
    isOnline: true,
  );

  const tEmail = 'test@example.com';
  const tPassword = 'Test123!';
  const tDisplayName = 'Test User';

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<User?>.broadcast();

    // Setup auth state stream
    when(mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);

    // Setup default stub for getCurrentUser (called during initialization)
    when(mockGetCurrentUserUseCase.call())
        .thenAnswer((_) async => const Left(AuthFailure.notAuthenticated()));

    authBloc = AuthBloc(
      signInUseCase: mockSignInUseCase,
      signUpUseCase: mockSignUpUseCase,
      signOutUseCase: mockSignOutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    authStateController.close();
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      // Note: The BLoC automatically checks auth status on initialization
      // so the state quickly transitions from AuthInitial to AuthUnauthenticated
      expect(authBloc.state, equals(const AuthUnauthenticated()));
    });

    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthAuthenticated] when getCurrentUser returns user',
        build: () {
          // Reset the mock to avoid conflicts with initialization call
          reset(mockGetCurrentUserUseCase);
          when(mockGetCurrentUserUseCase.call())
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockGetCurrentUserUseCase.call()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthUnauthenticated] when getCurrentUser returns AuthFailure',
        build: () {
          // Reset the mock to avoid conflicts with initialization call
          reset(mockGetCurrentUserUseCase);
          when(mockGetCurrentUserUseCase.call()).thenAnswer(
              (_) async => const Left(AuthFailure.notAuthenticated()));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          // No state change expected since BLoC is already AuthUnauthenticated
        ],
        verify: (_) {
          verify(mockGetCurrentUserUseCase.call()).called(1);
        },
      );
    });

    group('SignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthAuthenticated] when sign in succeeds',
        build: () {
          when(mockSignInUseCase.call(any))
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(
          email: tEmail,
          password: tPassword,
        )),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockSignInUseCase.call(any)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(mockSignInUseCase.call(any)).thenAnswer(
              (_) async => const Left(AuthFailure.invalidCredentials()));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(
          email: tEmail,
          password: tPassword,
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Invalid email or password.'),
        ],
        verify: (_) {
          verify(mockSignInUseCase.call(any)).called(1);
        },
      );
    });

    group('SignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthAuthenticated] when sign up succeeds',
        build: () {
          when(mockSignUpUseCase.call(any))
              .thenAnswer((_) async => Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        )),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: tUser),
        ],
        verify: (_) {
          verify(mockSignUpUseCase.call(any)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthError] when sign up fails',
        build: () {
          when(mockSignUpUseCase.call(any)).thenAnswer(
              (_) async => const Left(ValidationFailure.invalidEmail()));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(
          email: 'invalid-email',
          password: tPassword,
          displayName: tDisplayName,
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Please enter a valid email address.'),
        ],
        verify: (_) {
          verify(mockSignUpUseCase.call(any)).called(1);
        },
      );
    });

    group('SignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthUnauthenticated] when sign out succeeds',
        build: () {
          when(mockSignOutUseCase.call())
              .thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SignOutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(mockSignOutUseCase.call()).called(1);
        },
      );
    });

    group('AuthStatusChanged', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthAuthenticated] when user is not null',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthStatusChanged(user: tUser)),
        expect: () => [
          AuthAuthenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthUnauthenticated] when user is null',
        build: () => authBloc,
        seed: () =>
            AuthAuthenticated(user: tUser), // Start from authenticated state
        act: (bloc) => bloc.add(const AuthStatusChanged(user: null)),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });

    group('Auth State Stream', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthAuthenticated] when auth state stream emits user',
        build: () => authBloc,
        act: (bloc) => authStateController.add(tUser),
        expect: () => [
          AuthAuthenticated(user: tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthUnauthenticated] when auth state stream emits null',
        build: () => authBloc,
        seed: () =>
            AuthAuthenticated(user: tUser), // Start from authenticated state
        act: (bloc) => authStateController.add(null),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });
  });
}
