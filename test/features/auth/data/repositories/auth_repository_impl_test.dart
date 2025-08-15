import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/core/utils/logger.dart';
import 'package:flutter_real_time_chat/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_real_time_chat/features/auth/data/models/user_model.dart';
import 'package:flutter_real_time_chat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource, Logger])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockLogger mockLogger;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLogger = MockLogger();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      logger: mockLogger,
    );
  });

  group('AuthRepositoryImpl', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tDisplayName = 'Test User';
    const tUserId = 'user123';

    final tUserModel = UserModel(
      id: tUserId,
      email: tEmail,
      displayName: tDisplayName,
      photoUrl: null,
      createdAt: DateTime(2023, 1, 1),
      lastSeen: DateTime(2023, 1, 1),
      isOnline: true,
    );

    group('signIn', () {
      test('should return User when sign in is successful', () async {
        // arrange
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signIn(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, equals(Right(tUserModel)));
        verify(mockRemoteDataSource.signIn(
          email: tEmail,
          password: tPassword,
        ));
      });

      test('should return ValidationFailure when email is empty', () async {
        // act
        final result = await repository.signIn(
          email: '',
          password: tPassword,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should return ValidationFailure when email format is invalid',
          () async {
        // act
        final result = await repository.signIn(
          email: 'invalid-email',
          password: tPassword,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should return ValidationFailure when password is empty', () async {
        // act
        final result = await repository.signIn(
          email: tEmail,
          password: '',
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should return ValidationFailure when password is too short',
          () async {
        // act
        final result = await repository.signIn(
          email: tEmail,
          password: '123',
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
            const AuthException('Invalid credentials', code: 'wrong-password'));

        // act
        final result = await repository.signIn(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.signIn(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test('should return ServerFailure when unexpected exception is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.signIn(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ServerFailure>(),
        );
      });
    });

    group('signUp', () {
      test('should return User when sign up is successful', () async {
        // arrange
        when(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );

        // assert
        expect(result, equals(Right(tUserModel)));
        verify(mockRemoteDataSource.signUp(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        ));
      });

      test('should return ValidationFailure when display name is empty',
          () async {
        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: '',
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ));
      });

      test('should return ValidationFailure when display name is too short',
          () async {
        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: 'A',
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ));
      });

      test('should return ValidationFailure when display name is too long',
          () async {
        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: 'A' * 51, // 51 characters
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ));
      });

      test(
          'should return ValidationFailure when display name contains invalid characters',
          () async {
        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: 'Test@User!',
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        ));
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenThrow(const AuthException('Email already in use',
            code: 'email-already-in-use'));

        // act
        final result = await repository.signUp(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });
    });

    group('signOut', () {
      test('should return success when sign out is successful', () async {
        // arrange
        when(mockRemoteDataSource.signOut()).thenAnswer((_) async {});

        // act
        final result = await repository.signOut();

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.signOut());
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.signOut())
            .thenThrow(const AuthException('Sign out failed'));

        // act
        final result = await repository.signOut();

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.signOut())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.signOut();

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return User when getting current user is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(Right(tUserModel)));
        verify(mockRemoteDataSource.getCurrentUser());
      });

      test(
          'should return cached user when network error occurs and user is cached',
          () async {
        // arrange
        // First, cache a user by calling a successful method
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => tUserModel);
        await repository.signIn(email: tEmail, password: tPassword);

        // Then simulate network error
        when(mockRemoteDataSource.getCurrentUser())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(Right(tUserModel)));
      });

      test(
          'should return NetworkFailure when network error occurs and no cached user',
          () async {
        // arrange
        when(mockRemoteDataSource.getCurrentUser())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.getCurrentUser())
            .thenThrow(const AuthException('No authenticated user'));

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });
    });

    group('authStateChanges', () {
      test('should return stream of User when auth state changes', () async {
        // arrange
        when(mockRemoteDataSource.authStateChanges)
            .thenAnswer((_) => Stream.value(tUserModel));

        // act
        final stream = repository.authStateChanges;

        // assert
        expect(stream, emits(tUserModel));
      });

      test('should return stream of null when user signs out', () async {
        // arrange
        when(mockRemoteDataSource.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        // act
        final stream = repository.authStateChanges;

        // assert
        expect(stream, emits(null));
      });

      test('should handle error gracefully when network error occurs in stream',
          () async {
        // arrange
        // First, cache a user
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => tUserModel);
        await repository.signIn(email: tEmail, password: tPassword);

        // Then simulate stream with error
        when(mockRemoteDataSource.authStateChanges).thenAnswer(
            (_) => Stream.error(const SocketException('Network error')));

        // act
        final stream = repository.authStateChanges;

        // assert
        expect(stream, emitsError(isA<SocketException>()));
      });
    });

    group('updateUserProfile', () {
      const tNewDisplayName = 'Updated Name';
      const tPhotoUrl = 'https://example.com/photo.jpg';

      final tUpdatedUserModel = tUserModel.copyWith(
        displayName: tNewDisplayName,
        photoUrl: tPhotoUrl,
      );

      test('should return updated User when profile update is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.updateUserProfile(
          displayName: anyNamed('displayName'),
          photoUrl: anyNamed('photoUrl'),
        )).thenAnswer((_) async => tUpdatedUserModel);

        // act
        final result = await repository.updateUserProfile(
          displayName: tNewDisplayName,
          photoUrl: tPhotoUrl,
        );

        // assert
        expect(result, equals(Right(tUpdatedUserModel)));
        verify(mockRemoteDataSource.updateUserProfile(
          displayName: tNewDisplayName,
          photoUrl: tPhotoUrl,
        ));
      });

      test('should return ValidationFailure when display name is invalid',
          () async {
        // act
        final result = await repository.updateUserProfile(
          displayName: 'A', // Too short
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.updateUserProfile(
          displayName: anyNamed('displayName'),
          photoUrl: anyNamed('photoUrl'),
        ));
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.updateUserProfile(
          displayName: anyNamed('displayName'),
          photoUrl: anyNamed('photoUrl'),
        )).thenThrow(const AuthException('Update failed'));

        // act
        final result = await repository.updateUserProfile(
          displayName: tNewDisplayName,
        );

        // assert
        expect(result, isA<Left<Failure, User>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });
    });

    group('updateOnlineStatus', () {
      test('should return success when online status update is successful',
          () async {
        // arrange
        // First cache a user
        when(mockRemoteDataSource.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => tUserModel);
        await repository.signIn(email: tEmail, password: tPassword);

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => tUserModel);
        when(mockRemoteDataSource.updateOnlineStatus(
          userId: anyNamed('userId'),
          isOnline: anyNamed('isOnline'),
        )).thenAnswer((_) async {});

        // act
        final result = await repository.updateOnlineStatus(isOnline: true);

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.updateOnlineStatus(
          userId: tUserId,
          isOnline: true,
        ));
      });

      test('should return AuthFailure when no current user', () async {
        // arrange
        when(mockRemoteDataSource.getCurrentUser())
            .thenThrow(const AuthException('No authenticated user'));

        // act
        final result = await repository.updateOnlineStatus(isOnline: true);

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test(
          'should return success when password reset email is sent successfully',
          () async {
        // arrange
        when(mockRemoteDataSource.sendPasswordResetEmail(
          email: anyNamed('email'),
        )).thenAnswer((_) async {});

        // act
        final result = await repository.sendPasswordResetEmail(email: tEmail);

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.sendPasswordResetEmail(email: tEmail));
      });

      test('should return ValidationFailure when email is invalid', () async {
        // act
        final result =
            await repository.sendPasswordResetEmail(email: 'invalid-email');

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<ValidationFailure>(),
        );
        verifyNever(mockRemoteDataSource.sendPasswordResetEmail(
          email: anyNamed('email'),
        ));
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.sendPasswordResetEmail(
          email: anyNamed('email'),
        )).thenThrow(const AuthException('Failed to send email'));

        // act
        final result = await repository.sendPasswordResetEmail(email: tEmail);

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });
    });

    group('deleteAccount', () {
      test('should return success when account deletion is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.deleteAccount()).thenAnswer((_) async {});

        // act
        final result = await repository.deleteAccount();

        // assert
        expect(result, equals(const Right(null)));
        verify(mockRemoteDataSource.deleteAccount());
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(mockRemoteDataSource.deleteAccount())
            .thenThrow(const AuthException('Deletion failed'));

        // act
        final result = await repository.deleteAccount();

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<AuthFailure>(),
        );
      });

      test('should return NetworkFailure when SocketException is thrown',
          () async {
        // arrange
        when(mockRemoteDataSource.deleteAccount())
            .thenThrow(const SocketException('No internet connection'));

        // act
        final result = await repository.deleteAccount();

        // assert
        expect(result, isA<Left<Failure, void>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<NetworkFailure>(),
        );
      });
    });
  });
}
