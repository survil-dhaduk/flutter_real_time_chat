import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] that handles authentication operations
/// with proper error mapping and offline support
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // Cache for offline support
  UserModel? _cachedUser;
  StreamController<User?>? _authStateController;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    Logger? logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger ?? const Logger();

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('AuthRepository: Attempting sign in for email: $email');

      // Validate input
      final validationResult = _validateSignInInput(email, password);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Attempt sign in
      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );

      // Cache user for offline support
      _cachedUser = userModel;
      _logger
          .info('AuthRepository: Successfully signed in user: ${userModel.id}');

      return Right(userModel);
    } on AuthException catch (e) {
      _logger
          .error('AuthRepository: Auth exception during sign in: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger
          .error('AuthRepository: Network error during sign in: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('AuthRepository: Unexpected error during sign in: $e');
      return Left(ServerFailure('Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _logger.info('AuthRepository: Attempting sign up for email: $email');

      // Validate input
      final validationResult =
          _validateSignUpInput(email, password, displayName);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Attempt sign up
      final userModel = await _remoteDataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Cache user for offline support
      _cachedUser = userModel;
      _logger
          .info('AuthRepository: Successfully signed up user: ${userModel.id}');

      return Right(userModel);
    } on AuthException catch (e) {
      _logger
          .error('AuthRepository: Auth exception during sign up: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger
          .error('AuthRepository: Network error during sign up: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('AuthRepository: Unexpected error during sign up: $e');
      return Left(ServerFailure('Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      _logger.info('AuthRepository: Attempting sign out');

      await _remoteDataSource.signOut();

      // Clear cached user
      _cachedUser = null;
      _logger.info('AuthRepository: Successfully signed out');

      return const Right(null);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception during sign out: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger
          .error('AuthRepository: Network error during sign out: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('AuthRepository: Unexpected error during sign out: $e');
      return Left(ServerFailure('Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      _logger.info('AuthRepository: Getting current user');

      // Try to get user from remote source
      final userModel = await _remoteDataSource.getCurrentUser();

      // Cache user for offline support
      _cachedUser = userModel;
      _logger.info(
          'AuthRepository: Successfully retrieved current user: ${userModel.id}');

      return Right(userModel);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception getting current user: ${e.message}');

      // If network error and we have cached user, return cached user
      if (e.message.contains('network') && _cachedUser != null) {
        _logger
            .info('AuthRepository: Returning cached user due to network error');
        return Right(_cachedUser!);
      }

      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger.error(
          'AuthRepository: Network error getting current user: ${e.message}');

      // Return cached user if available during network issues
      if (_cachedUser != null) {
        _logger
            .info('AuthRepository: Returning cached user due to network error');
        return Right(_cachedUser!);
      }

      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger
          .error('AuthRepository: Unexpected error getting current user: $e');
      return Left(ServerFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    try {
      _logger.info('AuthRepository: Creating auth state changes stream');

      return _remoteDataSource.authStateChanges.map((userModel) {
        if (userModel != null) {
          // Cache user for offline support
          _cachedUser = userModel;
          _logger.info(
              'AuthRepository: Auth state changed - user authenticated: ${userModel.id}');
        } else {
          // Clear cached user when signed out
          _cachedUser = null;
          _logger.info('AuthRepository: Auth state changed - user signed out');
        }
        return userModel;
      }).handleError((error) {
        _logger.error(
            'AuthRepository: Error in auth state changes stream: $error');
        // Re-throw the error to let the caller handle it
        throw error;
      });
    } catch (e) {
      _logger.error(
          'AuthRepository: Error creating auth state changes stream: $e');

      // Return a stream that emits cached user if available, otherwise null
      return Stream.value(_cachedUser);
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _logger.info('AuthRepository: Updating user profile');

      // Validate input
      if (displayName != null) {
        final validationResult = _validateDisplayName(displayName);
        if (validationResult != null) {
          return Left(validationResult);
        }
      }

      // Update profile
      final userModel = await _remoteDataSource.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      // Update cached user
      _cachedUser = userModel;
      _logger.info(
          'AuthRepository: Successfully updated user profile: ${userModel.id}');

      return Right(userModel);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception updating profile: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger.error(
          'AuthRepository: Network error updating profile: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('AuthRepository: Unexpected error updating profile: $e');
      return Left(ServerFailure('Failed to update profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
  }) async {
    try {
      _logger.info('AuthRepository: Updating online status to: $isOnline');

      // Get current user ID
      final currentUserResult = await getCurrentUser();
      if (currentUserResult.isLeft()) {
        return Left(currentUserResult.fold(
            (failure) => failure, (_) => const AuthFailure.notAuthenticated()));
      }

      final currentUser =
          currentUserResult.getOrElse(() => throw Exception('No user'));

      await _remoteDataSource.updateOnlineStatus(
        userId: currentUser.id,
        isOnline: isOnline,
      );

      // Update cached user
      if (_cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(isOnline: isOnline);
      }

      _logger.info('AuthRepository: Successfully updated online status');
      return const Right(null);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception updating online status: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger.error(
          'AuthRepository: Network error updating online status: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger
          .error('AuthRepository: Unexpected error updating online status: $e');
      return Left(
          ServerFailure('Failed to update online status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      _logger.info('AuthRepository: Sending password reset email to: $email');

      // Validate email
      final validationResult = _validateEmail(email);
      if (validationResult != null) {
        return Left(validationResult);
      }

      await _remoteDataSource.sendPasswordResetEmail(email: email);
      _logger.info('AuthRepository: Successfully sent password reset email');

      return const Right(null);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception sending password reset: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger.error(
          'AuthRepository: Network error sending password reset: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger
          .error('AuthRepository: Unexpected error sending password reset: $e');
      return Left(ServerFailure(
          'Failed to send password reset email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      _logger.info('AuthRepository: Deleting user account');

      await _remoteDataSource.deleteAccount();

      // Clear cached user
      _cachedUser = null;
      _logger.info('AuthRepository: Successfully deleted user account');

      return const Right(null);
    } on AuthException catch (e) {
      _logger.error(
          'AuthRepository: Auth exception deleting account: ${e.message}');
      return Left(_mapAuthException(e));
    } on SocketException catch (e) {
      _logger.error(
          'AuthRepository: Network error deleting account: ${e.message}');
      return const Left(NetworkFailure.general());
    } catch (e) {
      _logger.error('AuthRepository: Unexpected error deleting account: $e');
      return Left(ServerFailure('Failed to delete account: ${e.toString()}'));
    }
  }

  /// Maps [AuthException] to appropriate [Failure] types
  Failure _mapAuthException(AuthException exception) {
    final message = exception.message.toLowerCase();
    final code = exception.code?.toLowerCase();

    // Map based on error codes first
    if (code != null) {
      switch (code) {
        case 'user-not-found':
          return const AuthFailure.userNotFound();
        case 'wrong-password':
        case 'invalid-credential':
          return const AuthFailure.invalidCredentials();
        case 'email-already-in-use':
          return const AuthFailure.emailAlreadyInUse();
        case 'weak-password':
          return const AuthFailure.weakPassword();
        case 'user-disabled':
          return const AuthFailure.accountDisabled();
        case 'too-many-requests':
          return const AuthFailure.tooManyRequests();
        case 'network-request-failed':
          return const NetworkFailure.general();
        case 'invalid-email':
          return const ValidationFailure.invalidEmail();
      }
    }

    // Map based on message content
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure.general();
    }
    if (message.contains('not authenticated') || message.contains('no user')) {
      return const AuthFailure.notAuthenticated();
    }
    if (message.contains('invalid email')) {
      return const ValidationFailure.invalidEmail();
    }
    if (message.contains('weak password')) {
      return const AuthFailure.weakPassword();
    }

    // Default to AuthFailure
    return AuthFailure(exception.message);
  }

  /// Validates sign in input parameters
  ValidationFailure? _validateSignInInput(String email, String password) {
    final emailValidation = _validateEmail(email);
    if (emailValidation != null) return emailValidation;

    final passwordValidation = _validatePassword(password);
    if (passwordValidation != null) return passwordValidation;

    return null;
  }

  /// Validates sign up input parameters
  ValidationFailure? _validateSignUpInput(
      String email, String password, String displayName) {
    final emailValidation = _validateEmail(email);
    if (emailValidation != null) return emailValidation;

    final passwordValidation = _validatePassword(password);
    if (passwordValidation != null) return passwordValidation;

    final displayNameValidation = _validateDisplayName(displayName);
    if (displayNameValidation != null) return displayNameValidation;

    return null;
  }

  /// Validates email format
  ValidationFailure? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return const ValidationFailure.emptyField('Email');
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return const ValidationFailure.invalidEmail();
    }

    return null;
  }

  /// Validates password strength
  ValidationFailure? _validatePassword(String password) {
    if (password.isEmpty) {
      return const ValidationFailure.emptyField('Password');
    }

    if (password.length < 6) {
      return const ValidationFailure.invalidPassword();
    }

    return null;
  }

  /// Validates display name
  ValidationFailure? _validateDisplayName(String displayName) {
    if (displayName.trim().isEmpty) {
      return const ValidationFailure.emptyField('Display name');
    }

    if (displayName.trim().length < 2) {
      return const ValidationFailure.invalidDisplayName();
    }

    if (displayName.trim().length > 50) {
      return const ValidationFailure.fieldTooLong('Display name', 50);
    }

    // Check for invalid characters (only allow letters, numbers, spaces, and basic punctuation)
    final validNameRegex = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');
    if (!validNameRegex.hasMatch(displayName.trim())) {
      return const ValidationFailure.invalidDisplayName();
    }

    return null;
  }

  /// Disposes resources
  void dispose() {
    _authStateController?.close();
    _cachedUser = null;
  }
}
