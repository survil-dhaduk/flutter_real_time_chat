import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Signs in a user with email and password
  ///
  /// Returns [Right<User>] on successful authentication
  /// Returns [Left<Failure>] on authentication failure
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Signs up a new user with email, password, and display name
  ///
  /// Returns [Right<User>] on successful registration
  /// Returns [Left<Failure>] on registration failure
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs out the current user
  ///
  /// Returns [Right<void>] on successful sign out
  /// Returns [Left<Failure>] on sign out failure
  Future<Either<Failure, void>> signOut();

  /// Gets the current authenticated user
  ///
  /// Returns [Right<User>] if user is authenticated
  /// Returns [Left<Failure>] if user is not authenticated or error occurs
  Future<Either<Failure, User>> getCurrentUser();

  /// Stream of authentication state changes
  ///
  /// Emits [User] when user is authenticated
  /// Emits [null] when user is not authenticated
  Stream<User?> get authStateChanges;

  /// Updates the current user's profile information
  ///
  /// Returns [Right<User>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Updates the user's online status
  ///
  /// Returns [Right<void>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
  });

  /// Sends a password reset email to the specified email address
  ///
  /// Returns [Right<void>] on successful email sent
  /// Returns [Left<Failure>] on failure to send email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Deletes the current user's account
  ///
  /// Returns [Right<void>] on successful account deletion
  /// Returns [Left<Failure>] on deletion failure
  Future<Either<Failure, void>> deleteAccount();
}
